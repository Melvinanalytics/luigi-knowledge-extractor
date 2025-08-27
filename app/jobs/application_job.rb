class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked
  
  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError
  
  # Retry on OpenAI API errors with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3 do |job, exception|
    Rails.logger.error "Job #{job.class.name} failed with #{exception.class.name}: #{exception.message}"
  end
end