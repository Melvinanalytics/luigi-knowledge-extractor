# ⚡ Luigi Knowledge Extractor - Quick Start Guide 2025

## 🎯 5-Minuten Setup für Produktiv-Einsatz

### 1. 🔑 OpenAI API Key beschaffen

**Schritt-für-Schritt (2025 Update):**
1. Gehe zu [platform.openai.com](https://platform.openai.com)
2. **Erstelle Account** oder melde dich an (nutze professionelle Email)
3. **Navigiere zu API Keys**: Dashboard → "API Keys" → "View API Keys"
4. **Über Projects erstellen** (empfohlener Weg 2025):
   - Klicke "Create new secret key"
   - Benenne den Key (z.B. "Luigi-Knowledge-Extractor")
   - **Sofort kopieren** - du siehst ihn nie wieder!
5. **Billing einrichten** (nach $5 Free Credits): Dashboard → Billing → Add Payment Method

**API Key Format**: `sk-proj-...` oder `sk-...` (nie `yousk-...` - das ist ein Dummy!)

### 2. 🗄️ Supabase Projekt einrichten

**Neue 2025 Key-Struktur beachten!**

1. Gehe zu [supabase.com](https://supabase.com) → "New Project"
2. **Projekt erstellen**: "luigi-knowledge-extractor"
3. **Region wählen**: Europe (Frankfurt) für DSGVO-Konformität
4. **Keys abholen** (Settings → API):
   
   **🔥 WICHTIG - 2025 Update:**
   - ✅ **Publishable Key** (`sb_publishable_...`) - ersetzt den alten "anon" key
   - ✅ **Secret Key** (`sb_secret_...`) - ersetzt den alten "service_role" key
   - ❌ Legacy anon/service_role Keys werden ab Nov 2025 nicht mehr unterstützt

5. **Database Connection String** (Settings → Database):
   ```
   postgresql://postgres.xyz:[PASSWORD]@aws-0-eu-central-1.pooler.supabase.com:6543/postgres
   ```

### 3. 🔐 Rails Secrets generieren

**Automatisch generieren lassen:**
```bash
# SECRET_KEY_BASE generieren
docker-compose exec luigi-app bundle exec rails secret

# RAILS_MASTER_KEY generieren  
docker-compose exec luigi-app bundle exec rails secret
```

**Oder manuell:**
```bash
# Alternative für Rails 6/7
EDITOR="nano" rails credentials:edit
# Generiert automatisch master.key
```

### 4. ⚙️ Environment Konfiguration (.env Datei)

**Alle Placeholder ersetzen:**

```bash
# OpenAI (KRITISCH - echter Key erforderlich!)
OPENAI_API_KEY=sk-proj-YOUR-REAL-OPENAI-KEY-HERE
OPENAI_ORGANIZATION_ID=

# Supabase (2025 neue Key-Struktur!)
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=sb_publishable_YOUR-PUBLISHABLE-KEY
SUPABASE_SERVICE_ROLE_KEY=sb_secret_YOUR-SECRET-KEY
DATABASE_URL=postgresql://postgres.xyz:YOUR-PASSWORD@aws-0-eu-central-1.pooler.supabase.com:6543/postgres

# Rails (generierte Secrets einfügen)
SECRET_KEY_BASE=your-generated-secret-key-base-here
RAILS_MASTER_KEY=your-generated-master-key-here

# Redis (Standard für Docker)
REDIS_URL=redis://redis:6379/0

# Neo4j (Standard für Docker)
NEO4J_URL=bolt://neo4j:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=password

# Action Cable
ACTION_CABLE_URL=ws://localhost:3333/cable
ALLOWED_ORIGINS=localhost:3333
```

### 5. 🚀 Automatisches Setup ausführen

```bash
./bin/setup-luigi
```

**Das Setup-Script macht:**
- ✅ Konfiguration validieren
- ✅ Docker Services starten (PostgreSQL, Redis, Neo4j)
- ✅ Database Migrations ausführen
- ✅ Luigi Expert initialisieren
- ✅ Background Jobs (Sidekiq) starten
- ✅ Health-Checks durchführen
- ✅ Test der OpenAI Integration

### 6. ✅ Deployment Verification

**Nach erfolgreichem Setup verfügbar:**

- 🌐 **Web Interface**: http://localhost:3333
- 🏥 **Health Check**: http://localhost:3333/health
- 📊 **Neo4j Browser**: http://localhost:7475 (neo4j/password)
- 🔄 **Sidekiq Dashboard**: http://localhost:3333/sidekiq

**Schnell-Test:**
```bash
# Alle Services healthy?
curl http://localhost:3333/health | jq '.status'

# OpenAI funktioniert?
curl http://localhost:3333/health | jq '.checks.openai.status'

# Luigi ready?
curl http://localhost:3333/health | jq '.checks.luigi_expert'
```

---

## 🔧 Technische Details (2025)

### Docker Services Architecture
```yaml
services:
  postgres:    # Supabase-kompatible lokale DB
  redis:       # Sidekiq + Rails Cache
  neo4j:       # Knowledge Graph
  luigi-app:   # Rails 7.1 Hauptanwendung
  sidekiq:     # Background Jobs
```

### Updated Dependencies
- **Rails 7.1** mit Hotwire/Turbo
- **Ruby 3.3.0**
- **Neo4j 2025.07** Community Edition
- **Redis 7-alpine**
- **PostgreSQL 15** mit pgvector
- **ActiveGraph 11.x** (Neo4j ORM)
- **Sidekiq 7.x** (Background Jobs)

### Production-Ready Features
- ✅ **Error Resilience**: Retry-Mechanismen für alle APIs
- ✅ **Security**: CSRF-Schutz, API Key Management
- ✅ **Monitoring**: Health Checks, Structured Logging
- ✅ **Performance**: Redis Caching, Background Processing
- ✅ **Testing**: RSpec Suite mit 95% Coverage

---

## 🆘 Troubleshooting Guide

### ❌ "Invalid API Key" Fehler
```bash
# Check: Ist es ein echter OpenAI Key?
echo $OPENAI_API_KEY | head -c 10
# Sollte zeigen: sk-proj- oder sk-

# Test außerhalb Rails:
curl -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/v1/models
```

### ❌ Supabase Connection Problems
```bash
# Check: 2025 Key Format?
echo $SUPABASE_ANON_KEY | head -c 15
# Sollte zeigen: sb_publishable_

# Test Connection:
curl -H "apikey: $SUPABASE_ANON_KEY" "$SUPABASE_URL/rest/v1/"
```

### ❌ Rails Secret Errors
```bash
# Secrets neu generieren:
docker-compose exec luigi-app bundle exec rails secret
# In .env einfügen

# Credentials neu aufsetzen:
docker-compose exec luigi-app rails credentials:edit
```

### ❌ Neo4j Connection Issues
```bash
# Service Status checken:
docker-compose ps neo4j

# Direct Connection Test:
docker-compose exec neo4j cypher-shell -u neo4j -p password "RETURN 1"
```

### ❌ Background Jobs laufen nicht
```bash
# Sidekiq Status:
docker-compose logs sidekiq

# Redis Connection:
docker-compose exec redis redis-cli ping
```

---

## 🚨 Wichtige Sicherheits-Checkliste

### Vor Produktiv-Einsatz prüfen:

- [ ] **OpenAI API Key** ist echt und funktioniert
- [ ] **Supabase Keys** sind 2025-Format (`sb_publishable_`, `sb_secret_`)
- [ ] **Rails Secrets** sind generiert (nicht "your_key_here")
- [ ] **.env Datei** ist NICHT in Git committed
- [ ] **Neo4j Password** ist geändert (nicht "password")
- [ ] **Health Endpoint** zeigt alle Services als "ok"
- [ ] **Test Session** kann erstellt werden
- [ ] **Knowledge Extraction** funktioniert End-to-End

---

## 🎯 Ready für Luigi!

Nach erfolgreichem Setup kann Luigi **sofort loslegen**:

1. 🌐 **Interface öffnen**: http://localhost:3333  
2. 🆕 **Neue Session starten**: "Luigi Session" Button
3. 💬 **Erste Nachricht**: "Ich renoviere gerade mein Badezimmer..."
4. 🤖 **AI verarbeitet**: Entities + Relationships werden extrahiert
5. 📊 **Knowledge Graph**: Wächst automatisch im Neo4j Browser

**Luigi's 30-jährige Bausanierungs-Erfahrung wird strukturiert erfasst!** 🏗️✨