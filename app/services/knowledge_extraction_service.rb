class KnowledgeExtractionService
  include Dry::Monads[:result]
  
  def initialize(message)
    @message = message
    @session = message.luigi_session
    @openai_client = OpenAI::Client.new
    @start_time = Time.current
  end
  
  def call
    extract_knowledge
      .bind { |extraction| save_entities(extraction) }
      .bind { |extraction| save_relationships(extraction) }
      .bind { |extraction| update_knowledge_graph(extraction) }
      .bind { |extraction| generate_response(extraction) }
  end
  
  private
  
  def extract_knowledge
    prompt = build_extraction_prompt(@message.content)
    
    response = @openai_client.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: prompt }
        ],
        temperature: 0.3,
        max_tokens: 2000,
        response_format: { type: "json_object" }
      }
    )
    
    raw_content = response.dig("choices", 0, "message", "content")
    
    if raw_content.blank?
      Rails.logger.error "Empty response from OpenAI"
      return Success(fallback_extraction)
    end
    
    # Try to parse JSON with multiple strategies
    extraction = parse_json_with_fallback(raw_content)
    
    # Validate and normalize the parsed extraction
    normalized = normalize_extraction(extraction)
    
    Success(normalized)
  rescue => error
    Rails.logger.error "Knowledge extraction failed: #{error.message}"
    Rails.logger.error "Raw response: #{raw_content}"
    Success(fallback_extraction)  # Don't fail the whole process
  end
  
  private
  
  def parse_json_with_fallback(raw_content)
    # Strategy 1: Direct JSON parsing
    begin
      return JSON.parse(raw_content)
    rescue JSON::ParserError
      Rails.logger.warn "Direct JSON parsing failed, trying cleanup..."
    end
    
    # Strategy 2: Clean up common JSON errors
    cleaned_content = raw_content
      .gsub(/```json\n?/, '')  # Remove markdown code blocks
      .gsub(/```\n?$/, '')
      .gsub(/^\s*```/, '')
      .gsub(/[\u201C\u201D]/, '"')  # Replace smart quotes
      .strip
    
    begin
      return JSON.parse(cleaned_content)
    rescue JSON::ParserError
      Rails.logger.warn "Cleanup strategy failed, trying manual parsing..."
    end
    
    # Strategy 3: Manual extraction (very basic)
    extract_json_manually(raw_content)
  end
  
  def extract_json_manually(raw_content)
    Rails.logger.warn "Using manual JSON extraction fallback"
    
    # Extract basic information using regex patterns
    entities = []
    relationships = []
    follow_up_questions = []
    
    # Extract entities (very basic pattern matching)
    entity_matches = raw_content.scan(/"type":\s*"([^"]+)"[^}]*"value":\s*"([^"]+)"/i)
    entity_matches.each do |type, value|
      entities << {
        "type" => type,
        "value" => value,
        "confidence" => 0.7,
        "context" => "extracted via fallback"
      }
    end
    
    # Extract questions
    question_matches = raw_content.scan(/["']([^"']*\?)[^"']*["']/i)
    question_matches.flatten.first(3).each do |question|
      follow_up_questions << question if question.length > 10
    end
    
    {
      "entities" => entities,
      "relationships" => relationships,
      "follow_up_questions" => follow_up_questions,
      "concepts" => entities.map { |e| e["value"] }.uniq,
      "summary" => "Information extracted via fallback method",
      "confidence" => 0.6
    }
  end
  
  def normalize_extraction(extraction)
    # Validate extraction structure
    unless extraction.is_a?(Hash)
      Rails.logger.warn "Invalid extraction format, using fallback"
      return fallback_extraction
    end

    # Ensure all required keys exist with proper defaults
    {
      "entities" => normalize_entities(extraction["entities"]),
      "relationships" => normalize_relationships(extraction["relationships"]),
      "follow_up_questions" => normalize_questions(extraction["follow_up_questions"]),
      "concepts" => extract_array(extraction["concepts"]),
      "summary" => extraction["summary"]&.to_s || "No summary available",
      "confidence" => normalize_confidence(extraction["confidence"])
    }
  end
  
  def normalize_entities(entities)
    return [] unless entities.is_a?(Array)
    
    entities.filter_map do |entity|
      next unless entity.is_a?(Hash)
      next if entity["value"].blank? || entity["type"].blank?
      
      {
        "type" => entity["type"].to_s.strip,
        "value" => entity["value"].to_s.strip,
        "confidence" => normalize_confidence(entity["confidence"]),
        "context" => entity["context"]&.to_s || ""
      }
    end
  end
  
  def normalize_relationships(relationships)
    return [] unless relationships.is_a?(Array)
    
    relationships.filter_map do |rel|
      next unless rel.is_a?(Hash)
      next if rel["from"].blank? || rel["to"].blank? || rel["relation"].blank?
      
      {
        "from" => rel["from"].to_s.strip,
        "to" => rel["to"].to_s.strip,
        "relation" => rel["relation"].to_s.strip,
        "confidence" => normalize_confidence(rel["confidence"]),
        "context" => rel["context"]&.to_s || ""
      }
    end
  end
  
  def normalize_questions(questions)
    return [] unless questions.is_a?(Array)
    
    questions.filter_map do |q|
      next if q.blank?
      q.to_s.strip
    end.first(5)  # Limit to 5 questions
  end
  
  def extract_array(value)
    case value
    when Array
      value.map(&:to_s).reject(&:blank?)
    when String
      [value]
    else
      []
    end
  end
  
  def normalize_confidence(confidence)
    [[confidence.to_f, 0.0].max, 1.0].min
  end
  
  def fallback_extraction
    {
      "entities" => [],
      "relationships" => [],
      "follow_up_questions" => ["Kannst du mir mehr dazu erzählen?"],
      "concepts" => [],
      "summary" => "Conversation recorded without detailed extraction",
      "confidence" => 0.0
    }
  end
  
  def save_entities(extraction)
    entities = extraction["entities"]&.map do |entity_data|
      @session.luigi_entities.create!(
        luigi_message: @message,
        entity_type: entity_data["type"],
        entity_value: entity_data["value"],
        confidence: entity_data["confidence"],
        context: entity_data["context"]
      )
    end || []
    
    Success(extraction.merge("entity_objects" => entities))
  rescue ActiveRecord::RecordInvalid => error
    Rails.logger.error "Entity creation failed: #{error.message}"
    Failure("Failed to save entities: #{error.message}")
  end
  
  def save_relationships(extraction)
    relationships = extraction["relationships"]&.map do |rel_data|
      @session.luigi_relationships.create!(
        luigi_message: @message,
        from_entity: rel_data["from"],
        relation_type: rel_data["relation"],
        to_entity: rel_data["to"],
        confidence: rel_data["confidence"],
        context: rel_data["context"]
      )
    end || []
    
    Success(extraction.merge("relationship_objects" => relationships))
  rescue ActiveRecord::RecordInvalid => error
    Rails.logger.error "Relationship creation failed: #{error.message}"
    Failure("Failed to save relationships: #{error.message}")
  end
  
  def update_knowledge_graph(extraction)
    # Asynchronous Neo4j update
    KnowledgeGraph::UpdateGraphJob.perform_later(
      @session.id,
      @message.id,
      extraction.slice("entities", "relationships")
    )
    
    Success(extraction)
  end
  
  def generate_response(extraction)
    follow_up_questions = extraction["follow_up_questions"] || []
    confidence = extraction["confidence"] || 0.0
    processing_time = ((Time.current - @start_time) * 1000).round
    
    response_content = if follow_up_questions.any?
      build_intelligent_response(extraction, follow_up_questions.first)
    else
      "Das ist interessant! Erzähl mir mehr darüber."
    end
    
    assistant_message = @session.luigi_messages.create!(
      message_type: 'assistant',
      content: response_content,
      confidence_score: confidence,
      entities_extracted: extraction["entities"]&.length || 0,
      processing_time_ms: processing_time,
      metadata: {
        concepts_found: extraction["concepts"] || [],
        follow_up_questions: follow_up_questions,
        extraction_summary: extraction["summary"]
      }
    )
    
    Success(assistant_message)
  rescue ActiveRecord::RecordInvalid => error
    Rails.logger.error "Assistant message creation failed: #{error.message}"
    Failure("Failed to create response: #{error.message}")
  end
  
  def system_prompt
    <<~PROMPT
      Du bist ein Experte für die Extraktion von Bauwissen aus Expertengesprächen. 
      Luigi ist ein erfahrener Handwerker mit 30 Jahren Erfahrung in der Sanierung.

      Analysiere seine Aussage und extrahiere strukturiert:

      1. ENTITIES (mit Typ und Confidence 0.0-1.0):
         Typen: BuildingType, BuildingAge, RoomType, Damage, Material, Tool, Method, Cost, TimeFrame, Risk, Regulation, Quality, Brand, Measurement

      2. RELATIONSHIPS (zwischen Entities):
         Typen: TYPICALLY_HAS, REQUIRES, COSTS, TAKES_TIME, CAUSES, PREVENTS, COMPATIBLE_WITH, BETTER_THAN, USED_FOR, MEASURED_BY, LOCATED_IN, REPLACED_BY, IMPROVED_BY, DAMAGED_BY

      3. FOLLOW-UP QUESTIONS (3-5 intelligente Nachfragen):
         - Vertiefe technische Details
         - Frage nach Kosten und Zeitschätzungen  
         - Erkunde praktische Erfahrungen und Tricks
         - Frage nach typischen Problemen und Lösungen
         - Hole spezifische Materialempfehlungen

      4. CONCEPTS SUMMARY: Liste der wichtigsten Konzepte für UI-Anzeige
      5. SUMMARY: Kurze Zusammenfassung der Kernaussage

      Antworte NUR als valides JSON.
    PROMPT
  end
  
  def build_extraction_prompt(message_content)
    <<~PROMPT
      Luigi's Aussage: "#{message_content}"

      Kontext: Das ist Teil einer Wissenssession über Bausanierung. Luigi teilt seine 30-jährige Erfahrung.

      Antworte NUR als valides JSON:
      {
        "entities": [
          {"type": "BuildingType", "value": "1960er Nachkriegsbau", "confidence": 0.95, "context": "kurze Erklärung"}
        ],
        "relationships": [
          {"from": "1960er Nachkriegsbau", "relation": "TYPICALLY_HAS", "to": "Rohrleitungskorrosion", "confidence": 0.90, "context": "warum diese Verbindung"}
        ],
        "follow_up_questions": [
          "Wie erkennst du Rohrleitungskorrosion am schnellsten?",
          "Welche Materialien verwendest du für die Sanierung?"
        ],
        "concepts": ["1960er Nachkriegsbau", "Rohrleitungskorrosion", "Komplettsanierung"],
        "summary": "Luigi erklärt typische Probleme in Nachkriegsbauten",
        "confidence": 0.92
      }
    PROMPT
  end
  
  def build_intelligent_response(extraction, primary_question)
    entities = extraction["entities"] || []
    confidence = extraction["confidence"] || 0.0
    
    if entities.any?
      main_concept = entities.first["value"]
      
      case confidence
      when 0.8..1.0
        "Verstanden! Du sprichst von #{main_concept}. Das ist wertvolle Erfahrung!\n\n🤔 #{primary_question}"
      when 0.6..0.8
        "Interessant, du erwähnst #{main_concept}. Da würde ich gerne tiefer bohren:\n\n❓ #{primary_question}"
      else
        "Ich denke du redest über #{main_concept}, bin mir aber nicht ganz sicher.\n\n🔍 #{primary_question}"
      end
    else
      "Das klingt nach wichtiger Erfahrung!\n\n💭 #{primary_question}"
    end
  end
end