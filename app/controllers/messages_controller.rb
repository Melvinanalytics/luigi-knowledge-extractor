class MessagesController < ApplicationController
  before_action :set_session
  
  def create
    @message = @session.luigi_messages.build(message_params)
    
    if @message.save
      # Process knowledge extraction asynchronously
      KnowledgeExtractionJob.perform_later(@message.id)
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("messages", 
              partial: "messages/message", 
              locals: { message: @message }
            ),
            turbo_stream.replace("message_form", 
              partial: "messages/form", 
              locals: { session: @session, message: LuigiMessage.new }
            ),
            turbo_stream.append("messages",
              partial: "messages/processing_indicator"
            )
          ]
        end
        format.json { render json: { status: 'processing', message_id: @message.id } }
        format.html { redirect_to @session }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("message_form", 
            partial: "messages/form", 
            locals: { session: @session, message: @message }
          )
        end
        format.json { render json: @message.errors, status: :unprocessable_entity }
        format.html { redirect_to @session, alert: 'Nachricht konnte nicht gesendet werden.' }
      end
    end
  end
  
  private
  
  def set_session
    @session = LuigiSession.find(params[:session_id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.redirect_to(root_path) }
      format.json { render json: { error: 'Session not found' }, status: :not_found }
      format.html { redirect_to root_path, alert: 'Session nicht gefunden.' }
    end
  end
  
  def message_params
    params.require(:luigi_message).permit(:content, :message_type).merge(
      message_type: params[:luigi_message][:message_type] || 'user'
    )
  end
end