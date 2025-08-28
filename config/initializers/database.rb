# Database connection stability for production
if Rails.env.production?
  # Verify database connection on boot
  Rails.application.config.after_initialize do
    begin
      # Test database connection with timeout
      ActiveRecord::Base.connection.execute("SELECT 1")
      Rails.logger.info "✅ Database connection established successfully"
    rescue => e
      Rails.logger.warn "⚠️ Database connection failed: #{e.message}"
      Rails.logger.warn "Application will continue but database features may not work"
    end
  end

  # Configure connection pool for better stability
  Rails.application.config.before_configuration do
    if ENV['DATABASE_URL'].present?
      # Parse DATABASE_URL and add SSL parameter if missing
      uri = URI.parse(ENV['DATABASE_URL'])
      if uri.scheme == 'postgresql' && !uri.query&.include?('sslmode')
        # Add SSL requirement for Supabase
        ssl_param = uri.query.present? ? "&sslmode=require" : "sslmode=require"
        ENV['DATABASE_URL'] = "#{ENV['DATABASE_URL']}#{uri.query.present? ? '&' : '?'}#{ssl_param}"
        Rails.logger.info "🔒 Added SSL requirement to DATABASE_URL for production"
      end
    end
  end
end