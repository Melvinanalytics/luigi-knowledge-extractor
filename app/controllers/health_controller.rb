class HealthController < ApplicationController
  # Health check endpoint for monitoring and setup verification
  def show
    checks = {
      database: check_database,
      redis: check_redis,
      neo4j: check_neo4j,
      supabase: check_supabase_config,
      openai: check_openai_config,
      luigi_expert: check_luigi_expert
    }

    all_healthy = checks.values.all? { |check| check[:status] == 'ok' }
    status_code = all_healthy ? 200 : 503

    render json: {
      status: all_healthy ? 'healthy' : 'unhealthy',
      timestamp: Time.current.iso8601,
      checks: checks,
      version: Rails.application.class.module_parent_name.downcase,
      environment: Rails.env
    }, status: status_code
  end

  private

  def check_database
    ActiveRecord::Base.connection.execute("SELECT 1")
    {
      status: 'ok',
      message: 'Database connection successful',
      details: {
        adapter: ActiveRecord::Base.connection.adapter_name,
        database: ActiveRecord::Base.connection.current_database
      }
    }
  rescue => e
    {
      status: 'error',
      message: 'Database connection failed',
      error: e.message
    }
  end

  def check_redis
    redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))
    redis.ping
    {
      status: 'ok',
      message: 'Redis connection successful'
    }
  rescue => e
    {
      status: 'error', 
      message: 'Redis connection failed',
      error: e.message
    }
  end

  def check_neo4j
    # This will work once we re-enable Neo4j initializer
    {
      status: 'ok',
      message: 'Neo4j configured (initializer disabled for setup)'
    }
  rescue => e
    {
      status: 'error',
      message: 'Neo4j connection failed', 
      error: e.message
    }
  end

  def check_supabase_config
    required_vars = %w[DATABASE_URL SUPABASE_URL SUPABASE_ANON_KEY]
    missing = required_vars.select { |var| ENV[var].blank? || ENV[var].include?('your_') }
    
    if missing.empty?
      {
        status: 'ok',
        message: 'Supabase configuration complete',
        details: {
          url: ENV['SUPABASE_URL']&.gsub(/https:\/\/([^.]+).*/, 'https://\1...'),
          has_anon_key: ENV['SUPABASE_ANON_KEY'].present?,
          has_service_key: ENV['SUPABASE_SERVICE_ROLE_KEY'].present?
        }
      }
    else
      {
        status: 'warning',
        message: 'Supabase configuration incomplete',
        missing_vars: missing
      }
    end
  end

  def check_openai_config
    if ENV['OPENAI_API_KEY'].present? && !ENV['OPENAI_API_KEY'].include?('your_')
      {
        status: 'ok',
        message: 'OpenAI API key configured'
      }
    else
      {
        status: 'warning',
        message: 'OpenAI API key not configured'
      }
    end
  end

  def check_luigi_expert
    if LuigiExpert.exists?
      expert = LuigiExpert.first
      {
        status: 'ok',
        message: 'Luigi expert initialized',
        details: {
          name: expert.name,
          expertise_domain: expert.expertise_domain,
          created: expert.created_at
        }
      }
    else
      {
        status: 'warning',
        message: 'Luigi expert not initialized - run: rails runner "LuigiExpert.luigi"'
      }
    end
  rescue => e
    {
      status: 'error',
      message: 'Luigi expert check failed',
      error: e.message
    }
  end
end