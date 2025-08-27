class AudioTranscriptionService
  include Dry::Monads[:result]
  
  MAX_FILE_SIZE = 25.megabytes
  SUPPORTED_FORMATS = %w[mp3 mp4 wav webm m4a ogg].freeze
  
  def call(audio_file)
    validate_audio_file(audio_file)
      .bind { |file| save_temp_file(file) }
      .bind { |temp_path| transcribe_with_whisper(temp_path) }
      .bind { |response| parse_transcription_response(response) }
  end
  
  private
  
  def validate_audio_file(audio_file)
    return Failure("No audio file provided") unless audio_file
    
    if audio_file.size > MAX_FILE_SIZE
      return Failure("File size exceeds 25MB limit")
    end
    
    extension = file_extension(audio_file).downcase
    unless SUPPORTED_FORMATS.include?(extension)
      return Failure("Unsupported audio format. Supported: #{SUPPORTED_FORMATS.join(', ')}")
    end
    
    Success(audio_file)
  end
  
  def save_temp_file(uploaded_file)
    temp_path = Rails.root.join('tmp', "audio_#{SecureRandom.hex}.#{file_extension(uploaded_file)}")
    
    File.open(temp_path, 'wb') { |f| f.write(uploaded_file.read) }
    
    Success(temp_path.to_s)
  rescue => error
    Rails.logger.error "Failed to save temp file: #{error.message}"
    Failure("Failed to process audio file")
  end
  
  def transcribe_with_whisper(temp_path)
    client = OpenAI::Client.new
    
    response = client.audio(
      parameters: {
        model: "whisper-1",
        file: File.open(temp_path, "rb"),
        language: "de",
        response_format: "verbose_json",
        temperature: 0.0
      }
    )
    
    Success({ response: response, temp_path: temp_path })
  rescue => error
    Rails.logger.error "Whisper transcription failed: #{error.message}"
    Failure("Transcription failed: #{error.message}")
  ensure
    File.delete(temp_path) if temp_path && File.exist?(temp_path)
  end
  
  def parse_transcription_response(data)
    response = data[:response]
    
    transcription_data = {
      text: response["text"],
      confidence: extract_confidence(response),
      duration: response["duration"],
      language: response["language"],
      segments: response["segments"] || [],
      word_count: response["text"]&.split&.length || 0
    }
    
    Success(transcription_data)
  rescue => error
    Rails.logger.error "Failed to parse transcription response: #{error.message}"
    Failure("Failed to parse transcription")
  end
  
  def extract_confidence(response)
    segments = response["segments"] || []
    return 0.9 if segments.empty?
    
    # Calculate average confidence from log probabilities
    confidences = segments.map do |segment|
      avg_logprob = segment["avg_logprob"] || -1.0
      # Convert log probability to confidence (0-1 scale)
      Math.exp(avg_logprob.clamp(-3.0, 0.0))
    end
    
    confidences.empty? ? 0.9 : confidences.sum / confidences.length
  end
  
  def file_extension(uploaded_file)
    return "" unless uploaded_file&.original_filename
    
    File.extname(uploaded_file.original_filename).delete_prefix('.')
  end
end