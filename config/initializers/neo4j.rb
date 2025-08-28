# Skip Neo4j initialization during asset precompilation, console, rake tasks, and migrations
return if defined?(Rails::Console) || 
          ENV['PRECOMPILING_ASSETS'] || 
          File.basename($0) == 'rake' ||
          Rails.env.test? ||
          defined?(Rails::Generators) ||
          $0.include?('db:') ||
          $0.include?('assets:')

# Only initialize after server is fully ready - use after_initialize hook
Rails.application.config.after_initialize do
  # Start Neo4j connection in background thread to never block Rails startup
  Thread.new do
    sleep(10) # Give Rails and all services time to fully start
    
    begin
      # Skip if Neo4j URL not configured
      neo4j_url = ENV['NEO4J_URL']
      return unless neo4j_url.present?
      
      require 'active_graph'
      
      Rails.logger.info "Attempting Neo4j connection to #{neo4j_url}"

      # Wait for Neo4j container to be ready
      max_retries = 5
      retry_count = 0
      
      begin
        ActiveGraph::Base.driver = Neo4j::Driver::GraphDatabase.driver(
          neo4j_url,
          Neo4j::Driver::AuthTokens.basic(
            ENV.fetch("NEO4J_USER", "neo4j"), 
            ENV.fetch("NEO4J_PASSWORD", "ca89da59a6f152c503b9a87da37e4842")
          )
        )

        # Test connection with timeout
        Timeout.timeout(5) do
          ActiveGraph::Base.driver.session.run("RETURN 1").consume
        end

        # Configure logging only in development
        if Rails.env.development?
          ActiveGraph::Base.logger = Rails.logger
          ActiveGraph::Base.log_query = true
        end

        Rails.logger.info "✅ Neo4j connection established successfully"
      rescue => connection_error
        retry_count += 1
        if retry_count < max_retries
          Rails.logger.info "Neo4j not ready, retrying in 5 seconds (#{retry_count}/#{max_retries})"
          sleep(5)
          retry
        else
          raise connection_error
        end
      end
    rescue => e
      Rails.logger.warn "⚠️ Neo4j initialization failed: #{e.message}"
      Rails.logger.warn "Application will continue without Neo4j functionality"
      Rails.logger.warn "Knowledge graph features may not work until Neo4j is available"
    end
  end
end