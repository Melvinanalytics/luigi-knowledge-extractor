require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module LuigiKnowledgeExtractor
  class Application < Rails::Application
    config.load_defaults 7.1
    config.autoload_lib(ignore: %w(assets tasks))

    # ActiveJob configuration
    config.active_job.queue_adapter = :sidekiq
    
    # Action Cable configuration
    config.action_cable.mount_path = '/cable'
    config.action_cable.url = ENV.fetch("ACTION_CABLE_URL", 'ws://localhost:3333/cable')
    
    # Neo4j configuration will be in config/neo4j.rb
    
    # CORS configuration for API endpoints (rack-cors gem needed)
    # config.middleware.insert_before 0, Rack::Cors do
    #   allow do
    #     origins ENV.fetch("ALLOWED_ORIGINS", "localhost:3000").split(',')
    #     resource '*',
    #       headers: :any,
    #       methods: [:get, :post, :put, :patch, :delete, :options, :head],
    #       credentials: true
    #   end
    # end
    
    # Time zone
    config.time_zone = 'Berlin'
    
    # I18n configuration
    config.i18n.default_locale = :de
    config.i18n.available_locales = [:de, :en]
  end
end