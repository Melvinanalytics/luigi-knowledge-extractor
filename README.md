# Luigi Knowledge Extractor

Ein state-of-the-art Rails 7.1 System zur intelligenten Wissensextraktion aus Expertengesprächen mit Luigi, dem erfahrenen Handwerker.

## 🔧 Features

- **KI-basierte Wissensextraktion** mit OpenAI GPT-4
- **Voice-to-Text** mit OpenAI Whisper API
- **Real-time Chat** mit Hotwire/Turbo + WebSockets  
- **Knowledge Graph** in Neo4j für Wissensvernetzung
- **Intelligente Nachfragen** für systematische Wissensvertiefung
- **Export-Funktionen** für strukturierte Wissensbasis
- **Modern UI** mit Tailwind CSS + Stimulus

## 🏗️ Tech Stack

- **Backend**: Rails 7.1 + Ruby 3.3.0
- **Frontend**: Hotwire (Turbo + Stimulus) + Tailwind CSS
- **Database**: PostgreSQL + pgvector
- **Graph DB**: Neo4j 5 mit ActiveGraph
- **Cache/Jobs**: Redis + Sidekiq
- **AI Services**: OpenAI GPT-4 + Whisper
- **Patterns**: Dry::Monads für Service Objects

## 🚀 Quick Start

### Mit Docker (Empfohlen)

```bash
# Repository klonen
git clone <repository-url>
cd luigi-knowledge-extractor

# Environment Variables setzen
cp .env.example .env
# OPENAI_API_KEY und andere Keys eintragen

# Services starten
docker-compose up -d

# Database setup
docker-compose exec luigi-app rails db:create db:migrate

# Luigi Expert initialisieren
docker-compose exec luigi-app rails console
> LuigiExpert.luigi
```

### Lokale Entwicklung

```bash
# Dependencies installieren
bundle install
yarn install

# Services starten (benötigt PostgreSQL, Redis, Neo4j)
rails db:create db:migrate
rails server

# In separaten Terminals:
sidekiq -C config/sidekiq.yml
```

## 📋 Environment Variables

```bash
# AI Services
OPENAI_API_KEY=your_openai_api_key

# Supabase Configuration
DATABASE_URL=postgresql://postgres.xyz:[PASSWORD]@aws-0-eu-central-1.pooler.supabase.com:6543/postgres
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# Redis (Docker)
REDIS_URL=redis://localhost:6379/0

# Neo4j (Docker)
NEO4J_URL=bolt://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=password

# Production
RAILS_MASTER_KEY=your_master_key
ACTION_CABLE_URL=wss://your-domain.com/cable
```

## 🔧 Supabase Setup

**📖 Detailed Setup Instructions**: See [SUPABASE_SETUP.md](SUPABASE_SETUP.md)

1. Create Supabase project
2. Get your credentials (URL, anon key, service role key, DATABASE_URL)
3. Update `.env` file with your credentials
4. Run migrations: `docker-compose exec luigi-app rails db:migrate`

## 🎯 Verwendung

1. **Session starten**: Neue Wissenssession mit Luigi beginnen
2. **Gespräch führen**: Text eingeben oder Voice-Recording nutzen
3. **KI analysiert**: Automatische Extraktion von Konzepten und Beziehungen
4. **Nachfragen**: System stellt intelligente Follow-up Fragen
5. **Export**: Strukturiertes Wissen als JSON exportieren

### Voice Recording

- **Browser Speech Recognition**: Für sofortige Ergebnisse (Chrome/Edge)
- **Whisper API**: Für präzise Server-side Transkription
- **Format Support**: MP3, MP4, WAV, WebM, M4A, OGG

## 🏛️ Architektur

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Rails API     │    │  Background     │
│                 │    │                 │    │                 │
│ Stimulus.js     │◄──►│ Controllers     │◄──►│ Sidekiq Jobs    │
│ Hotwire/Turbo   │    │ Service Objects │    │ Knowledge       │
│ Action Cable    │    │ Models          │    │ Extraction      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │                        │
                              ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │     Neo4j       │    │   OpenAI API    │
│                 │    │                 │    │                 │
│ Sessions        │    │ Knowledge Graph │    │ GPT-4           │
│ Messages        │    │ Entities        │    │ Whisper         │
│ Entities        │    │ Relationships   │    │ Embeddings      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔄 Knowledge Extraction Flow

1. **User Input** → Text/Voice → `LuigiMessage`
2. **Background Job** → `KnowledgeExtractionJob`
3. **AI Analysis** → `KnowledgeExtractionService` → OpenAI GPT-4
4. **Entity Extraction** → `LuigiEntity` (PostgreSQL)
5. **Relationship Mapping** → `LuigiRelationship` (PostgreSQL)  
6. **Graph Update** → `KnowledgeGraph::UpdateGraphJob` → Neo4j
7. **Response Generation** → Intelligente Nachfrage
8. **Real-time Update** → Action Cable → Frontend

## 📊 Datenmodell

### PostgreSQL (Strukturierte Daten)
- `luigi_experts` - Expert-Profile
- `luigi_sessions` - Wissenssessions  
- `luigi_messages` - Chat-Nachrichten
- `luigi_entities` - Extrahierte Konzepte
- `luigi_relationships` - Konzept-Beziehungen

### Neo4j (Knowledge Graph)
- `ExpertNode` - Experten im Graph
- `KnowledgeEntity` - Wissenskonzepte
- `SessionNode` - Session-Verbindungen
- `RELATES_TO` - Wissensbeziehungen

## 🚀 Production Deployment

```bash
# Mit Docker Compose
docker-compose -f docker-compose.production.yml up -d

# Mit Kubernetes (Helm Chart verfügbar)
helm install luigi-knowledge ./helm-chart

# Environment-spezifische Konfiguration
# config/environments/production.rb
# config/database.yml
# config/sidekiq.yml
```

### Performance Optimierung

- **Redis Caching** für Session-Daten
- **Background Processing** für AI-Calls
- **Connection Pooling** für Datenbanken
- **Asset Pipeline** optimiert für Production
- **CDN Support** für statische Assets

## 🧪 Testing

```bash
# Test Suite ausführen
bundle exec rspec

# Spezifische Tests
bundle exec rspec spec/services/knowledge_extraction_service_spec.rb
bundle exec rspec spec/models/luigi_session_spec.rb

# Factories für Test-Daten
# spec/factories/luigi_sessions.rb
# spec/factories/luigi_messages.rb
```

## 🔧 Development

### Code Struktur

```
app/
├── controllers/          # Rails Controllers mit Turbo Streams
├── models/              # ActiveRecord + Neo4j Models
│   └── graph/           # Neo4j Graph Models
├── services/            # Business Logic mit Dry::Monads
├── jobs/               # Sidekiq Background Jobs
│   └── knowledge_graph/ # Neo4j Graph Updates
├── channels/           # Action Cable WebSocket Channels
├── views/              # ERB Templates mit Hotwire
└── javascript/         # Stimulus Controllers
    └── controllers/    # Frontend Interaction Logic
```

### Service Objects Pattern

```ruby
# Dry::Monads für saubere Service-Implementierung
class KnowledgeExtractionService
  include Dry::Monads[:result]
  
  def call
    extract_knowledge
      .bind { |data| save_entities(data) }
      .bind { |data| update_graph(data) }
      .bind { |data| generate_response(data) }
  end
end
```

## 📈 Monitoring

- **Rails Logger** für Application Logs
- **Sidekiq Web UI** für Job Monitoring  
- **Neo4j Browser** für Graph Exploration
- **PostgreSQL Stats** für Performance Monitoring

## 🤝 Contributing

1. Feature Branch erstellen
2. Tests implementieren
3. Code Review durch Team
4. CI/CD Pipeline durchlaufen
5. Deployment nach Approval

## 📜 License

Proprietary - Alle Rechte vorbehalten

## 📞 Support

Bei Fragen oder Issues:
- GitHub Issues für Bug Reports
- Slack #luigi-knowledge für Diskussionen
- Email: support@luigi-knowledge.com