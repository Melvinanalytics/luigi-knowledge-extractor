# 🚂 Railway.app Setup für Luigi Knowledge Extractor

## Schritt-für-Schritt Railway Deployment

### 1. Railway Account & Project
1. Gehe zu https://railway.app
2. **Sign up** mit GitHub Account
3. **New Project** → **Deploy from GitHub repo**
4. **Repository:** `Gino_Extraction` auswählen

### 2. PostgreSQL Service hinzufügen
1. **Add Service** → **Database** → **PostgreSQL**
2. Warten bis PostgreSQL läuft

### 3. Redis Service hinzufügen  
1. **Add Service** → **Database** → **Redis**
2. Warten bis Redis läuft

### 4. Neo4j Service hinzufügen
1. **Add Service** → **Docker Image**
2. **Image:** `neo4j:4.4`
3. **Port:** 7687, 7474

### 5. Environment Variables setzen

**Im Rails Service:**
```
RAILS_ENV=production
SECRET_KEY_BASE=1b5bafe817b2367ef2779d36e3ebb749cc1ae7ea7d808705bde80469c11b935f9cbe0c8d8acce3facd80424b31a9a727d6da56b8b2e723edb1c542dda79527cb
RAILS_MASTER_KEY=6fe1e4af3c8b2cd06dc7173b71ce27afacbdc2e6a3b9bf1af662d748bd5d426786f28dc3bccdd85b11b232523e04fd0f2dc03db7b6374403fc7558598e047d84
DATABASE_URL=${{Postgres.DATABASE_PUBLIC_URL}}
REDIS_URL=${{Redis.REDIS_PUBLIC_URL}}
NEO4J_URL=bolt://neo4j:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=ca89da59a6f152c503b9a87da37e4842
OPENAI_API_KEY=YOUR_OPENAI_API_KEY_HERE
PORT=3000
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

**Im Neo4j Service:**
```
NEO4J_AUTH=neo4j/ca89da59a6f152c503b9a87da37e4842
NEO4J_PLUGINS=["apoc"]
NEO4J_dbms_memory_heap_initial__size=256m
NEO4J_dbms_memory_heap_max__size=512m
NEO4J_dbms_connector_bolt_tls__level=DISABLED
NEO4J_dbms_connector_https_enabled=false
NEO4J_dbms_security_procedures_unrestricted=apoc.*
```

### 6. Domain generieren
1. **Rails Service** → **Settings** → **Generate Domain**
2. **URL wird sein:** `https://gino-extraction-production.railway.app`

### 7. Deploy starten
1. **Deploy** klicken
2. Logs überwachen
3. Warten bis alle Services laufen

### 8. Test der Live-URL
- **Luigi Website:** https://gino-extraction-production.railway.app  
- **Neo4j Browser:** https://neo4j-service-production.railway.app:7474

## ✅ RESULT: Öffentliche URLs statt localhost!

**Keine Docker-Probleme mehr - alles in der Cloud!** 🎯