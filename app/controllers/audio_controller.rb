class AudioController < ApplicationController
  def transcribe
    session_id = params[:session_id]
    audio_file = params[:audio]
    
    unless audio_file
      return render json: { error: 'No audio file provided' }, status: :bad_request
    end
    
    # Find session if provided
    session_obj = session_id ? LuigiSession.find(session_id) : nil
    
    # Transcribe audio
    result = AudioTranscriptionService.new.call(audio_file)
    
    handle_service_result(
      result,
      ->(transcription) { handle_successful_transcription(transcription, session_obj) },
      ->(error) { render json: { error: error }, status: :unprocessable_entity }
    )
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Session not found' }, status: :not_found
  end
  
  private
  
  def handle_successful_transcription(transcription, session_obj)
    response_data = {
      success: true,
      transcription: transcription[:text],
      confidence: transcription[:confidence].round(2),
      duration: transcription[:duration],
      word_count: transcription[:word_count]
    }
    
    # If session provided, create message and trigger processing
    if session_obj && transcription[:text].present?
      message = session_obj.luigi_messages.create!(
        message_type: 'user',
        content: transcription[:text],
        metadata: {
          transcription_confidence: transcription[:confidence],
          audio_duration: transcription[:duration],
          source: 'whisper_api',
          word_count: transcription[:word_count],
          language: transcription[:language]
        }
      )
      
      # Trigger knowledge extraction
      KnowledgeExtractionJob.perform_later(message.id)
      
      response_data[:message_id] = message.id
      response_data[:processing] = true
    end
    
    render json: response_data
  end
end