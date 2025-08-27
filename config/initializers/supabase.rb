# Supabase configuration
# Note: This uses standard PostgreSQL connection via DATABASE_URL
# Supabase provides a PostgreSQL-compatible database with pgvector extension

if Rails.env.development? || Rails.env.production?
  # Verify Supabase environment variables are set
  required_vars = %w[DATABASE_URL SUPABASE_URL SUPABASE_ANON_KEY]
  missing_vars = required_vars.select { |var| ENV[var].blank? || ENV[var].include?('your_') }
  
  if missing_vars.any?
    Rails.logger.warn "⚠️  Missing Supabase configuration: #{missing_vars.join(', ')}"
    Rails.logger.warn "🔧 Please update your .env file with your Supabase credentials"
    Rails.logger.warn "📖 See SUPABASE_SETUP.md for instructions"
  else
    Rails.logger.info "✅ Supabase configuration loaded successfully"
  end
end

# Optional: Add Supabase client gem configuration here if you add the supabase gem later
# Example:
# if defined?(Supabase)
#   Supabase.configure do |config|
#     config.url = ENV['SUPABASE_URL']
#     config.key = ENV['SUPABASE_ANON_KEY']
#   end
# end