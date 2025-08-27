# Skip Neo4j initialization during asset precompilation and early boot  
return if defined?(Rails::Console) || ENV['PRECOMPILING_ASSETS'] || File.basename($0) == 'rake'

# Initialize Neo4j connection in background thread to avoid blocking startup
Thread.new do
  sleep(5) # Give Rails time to fully start
  
  begin
    require 'active_graph'

    # Wait for Neo4j container to be ready
    max_retries = 10
    retry_count = 0
    
    begin
      ActiveGraph::Base.driver = Neo4j::Driver::GraphDatabase.driver(
        ENV.fetch("NEO4J_URL", "bolt://neo4j:7687"),
        Neo4j::Driver::AuthTokens.basic(
          ENV.fetch("NEO4J_USER", "neo4j"), 
          ENV.fetch("NEO4J_PASSWORD", "ca89da59a6f152c503b9a87da37e4842")
        )
      )

      # Test connection
      ActiveGraph::Base.driver.session.run("RETURN 1").consume

      # Configure logging
      if Rails.env.development?
        ActiveGraph::Base.logger = Rails.logger
        ActiveGraph::Base.log_query = true
      end

      Rails.logger.info "Neo4j connection established in background thread"
    rescue => connection_error
      retry_count += 1
      if retry_count < max_retries
        Rails.logger.info "Neo4j not ready, retrying in 2 seconds (#{retry_count}/#{max_retries})"
        sleep(2)
        retry
      else
        raise connection_error
      end
    end
  rescue => e
    Rails.logger.warn "Neo4j initialization failed after retries: #{e.message}"
    Rails.logger.warn "Application will continue without Neo4j functionality"
  end
end