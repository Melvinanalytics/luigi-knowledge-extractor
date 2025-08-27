Neo4j::ActiveGraph.configure do |config|
  config.driver = Neo4j::Driver::GraphDatabase.driver(
    ENV.fetch("NEO4J_URL", "bolt://localhost:7687"),
    Neo4j::Driver::AuthTokens.basic(
      ENV.fetch("NEO4J_USER", "neo4j"), 
      ENV.fetch("NEO4J_PASSWORD", "password")
    )
  )
end