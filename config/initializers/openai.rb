OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_API_KEY")
  config.organization_id = ENV["OPENAI_ORGANIZATION_ID"] # Optional
  config.log_errors = Rails.env.development?
  
  # Timeout configuration
  config.request_timeout = 240 # seconds
end