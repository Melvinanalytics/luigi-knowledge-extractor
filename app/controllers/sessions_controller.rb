class SessionsController < ApplicationController
  before_action :set_session, only: [:show, :export]
  
  def index
    @sessions = @luigi.luigi_sessions.recent.includes(:luigi_messages)
    @total_stats = {
      total_sessions: @sessions.count,
      total_knowledge: @luigi.luigi_sessions.sum(:entities_extracted),
      avg_confidence: @luigi.avg_session_confidence
    }
  end
  
  def show
    @messages = @session.luigi_messages
                        .includes(:luigi_entities, :luigi_relationships)
                        .chronological
    
    @stats = calculate_session_stats(@session)
    @new_message = LuigiMessage.new
    
    # Mark session as current
    session[:current_session_id] = @session.id
  end
  
  def create
    @session = @luigi.luigi_sessions.build(session_params)
    
    if @session.save
      session[:current_session_id] = @session.id
      
      # Create session in Neo4j asynchronously
      KnowledgeGraph::CreateSessionJob.perform_later(@session.id, @luigi.user_id)
      
      # Add welcome message
      create_welcome_message
      
      respond_to do |format|
        format.html { redirect_to @session, notice: 'Neue Wissenssession gestartet!' }
        format.turbo_stream do
          render turbo_stream: turbo_stream.redirect_to(@session)
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to root_path, alert: 'Session konnte nicht erstellt werden.' }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("session_form", 
            partial: "sessions/form", locals: { session: @session })
        end
      end
    end
  end
  
  def export
    result = KnowledgeExportService.new(@session).call
    
    handle_service_result(
      result,
      ->(export_data) {
        respond_to do |format|
          format.json do
            send_data export_data.to_json, 
              filename: "luigi-knowledge-#{@session.id}-#{Date.current}.json",
              type: 'application/json'
          end
          format.html { redirect_to @session, notice: 'Export wird heruntergeladen...' }
        end
      },
      ->(error) {
        respond_to do |format|
          format.json { render json: { error: error }, status: :unprocessable_entity }
          format.html { redirect_to @session, alert: "Export fehlgeschlagen: #{error}" }
        end
      }
    )
  end
  
  private
  
  def set_session
    @session = LuigiSession.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Session nicht gefunden.'
  end
  
  def session_params
    {
      session_name: "Luigi Session #{Time.current.strftime('%Y-%m-%d %H:%M')}",
      description: 'Knowledge extraction session for construction renovation expertise',
      status: 'active',
      started_at: Time.current
    }
  end
  
  def calculate_session_stats(session)
    {
      duration_seconds: session.duration_seconds,
      duration_formatted: session.duration_formatted,
      total_messages: session.total_messages,
      entities_extracted: session.entities_extracted,
      relationships_created: session.relationships_created,
      avg_confidence: session.avg_confidence.to_f.round(2),
      knowledge_density: session.knowledge_density.round(3)
    }
  end
  
  def create_welcome_message
    @session.luigi_messages.create!(
      message_type: 'system',
      content: welcome_message_content
    )
  end

  def welcome_message_content
    <<~MESSAGE
      Hallo Luigi! 🔧 

      Schön dich zu sehen. Erzähl mir von deinen Erfahrungen - ich strukturiere dein Wissen automatisch und stelle intelligente Fragen.

      💡 **Was passiert hier?**
      - Ich erkenne automatisch wichtige Konzepte aus deinen Erzählungen
      - Baue Verbindungen zwischen verschiedenen Themen auf
      - Stelle gezielte Nachfragen, um dein Wissen zu vertiefen
      
      Leg einfach los und erzähl mir, was dir gerade durch den Kopf geht! 🚀
    MESSAGE
  end
end