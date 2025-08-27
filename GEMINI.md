## Project Overview

This is the **Luigi Knowledge Extractor**, a sophisticated Ruby on Rails application designed to intelligently extract and structure knowledge from expert conversations. The project leverages a powerful combination of AI, a graph database, and real-time web technologies to create a dynamic knowledge base.

The core of the application is a chat interface where a user can interact with "Luigi," an expert persona. The system then uses AI to analyze the conversation, identify key concepts and relationships, and build a knowledge graph.

### Key Technologies

*   **Backend:** Ruby on Rails 7.1
*   **Frontend:** Hotwire (Turbo & Stimulus), Tailwind CSS
*   **Databases:**
    *   **Primary:** PostgreSQL (with pgvector for embeddings)
    *   **Graph:** Neo4j
*   **AI & Machine Learning:**
    *   OpenAI GPT-4 for knowledge extraction
    *   OpenAI Whisper for voice-to-text transcription
*   **Background Processing:** Sidekiq
*   **Caching:** Redis
*   **Containerization:** Docker

### Architecture

The application follows a standard Rails architecture, enhanced with specific services for its unique features:

*   **`app/services/knowledge_extraction_service.rb`**: This is the heart of the AI functionality, responsible for communicating with the OpenAI API to extract entities and relationships from the conversation.
*   **`app/jobs/knowledge_extraction_job.rb`**: This Sidekiq job orchestrates the knowledge extraction process in the background, ensuring the application remains responsive.
*   **`app/models/`**: The directory contains both ActiveRecord models for the PostgreSQL database and ActiveGraph models for the Neo4j graph database.
*   **`app/controllers/sessions_controller.rb`**: Manages the user's session and interaction with Luigi.
*   **Action Cable**: Used for real-time communication between the server and the client, providing a dynamic chat experience.

## Building and Running the Project

The project is containerized using Docker, which is the recommended way to run it.

### Prerequisites

*   Docker and Docker Compose
*   An OpenAI API key
*   A Supabase account for the PostgreSQL database

### Steps to Run

1.  **Clone the repository.**
2.  **Set up environment variables:**
    *   Copy `.env.example` to `.env`.
    *   Fill in the required credentials for your OpenAI API key and Supabase database.
3.  **Start the services:**
    ```bash
    docker-compose up -d
    ```
4.  **Set up the database:**
    ```bash
    docker-compose exec luigi-app rails db:create db:migrate
    ```
5.  **Access the application:**
    *   The application will be available at `http://localhost:3333`.
    *   The Neo4j browser can be accessed at `http://localhost:7475`.
    *   The Sidekiq dashboard is at `http://localhost:3333/sidekiq`.

### Testing

The project uses RSpec for testing. To run the test suite:

```bash
docker-compose exec luigi-app bundle exec rspec
```

## Development Conventions

*   **Service Objects:** Business logic is encapsulated in service objects, particularly for complex operations like AI-powered knowledge extraction. The `Dry::Monads` gem is used to handle success and failure cases gracefully.
*   **Background Jobs:** Long-running tasks, such as API calls to OpenAI, are handled asynchronously using Sidekiq to prevent blocking the main application thread.
*   **Styling:** The application uses Tailwind CSS for styling.
*   **Real-time Functionality:** Hotwire and Action Cable are used to provide a real-time, single-page application-like experience.
*   **Database:** The project uses both a relational database (PostgreSQL) for structured data and a graph database (Neo4j) to represent the relationships between extracted knowledge.
