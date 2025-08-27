# context.md - SanierungsOS Platform & Module Architecture

WIR BAUEN HIER NUR DIE DOMAIN KNOWLEDGE EXTRACTION

## Core Vision

**SanierungsOS** ist eine AI-first Multi-Agent-Plattform für die deutsche Sanierungsbranche. Die Plattform wird von Grund auf für die gleichzeitige Nutzung durch tausende Stakeholder konzipiert - mit einer event-driven Architektur, die massive Skalierung ermöglicht.

## Fundamental Architecture Principles

### Module-First Development
Jedes Modul wird als **standalone-fähige Einheit** entwickelt, die:
- Isoliert funktioniert und Wert liefert
- Über standardisierte Event-Interfaces kommuniziert
- Zukünftig nahtlos mit anderen Modulen orchestriert werden kann
- Keine harten Dependencies zu anderen Modulen hat

### Platform Evolution Strategy
Die Plattform befindet sich bewusst in einer **graduellen, intelligenten Entwicklungsphase**:
- Multi-Agent-Orchestration ist konzeptionell definiert, aber noch nicht vollständig implementiert
- Wir bewegen uns am "bleeding edge" der Technologie
- Jede Implementierung muss flexibel für zukünftige Orchestration-Patterns bleiben
- Event-driven von Tag 1, auch wenn Events initial nur lokal verarbeitet werden

## Module Dependencies & Information Flow

```
                    EstimationEngine
                  (Cost Truth Source)
                          ↓
        ┌─────────────────┼─────────────────┐
        ↓                 ↓                 ↓
   FörderMatrix    HandwerkerNetwork   VisionAnalyzer
   (needs costs)    (needs scope)     (enriches costs)
        ↓                 ↓                 ↓
        └─────────────────┼─────────────────┘
                          ↓
                   ProjectManager
                  (orchestrates all)
```

**Warum EstimationEngine zuerst?**
- Ohne Kosten keine Förderanträge
- Ohne Umfang keine Handwerkerauswahl
- Ohne Baseline keine Projekt-Kontrolle
- Ohne Schätzung keine Kundenentscheidung

## Current Module Portfolio

### EstimationEngine (In Development) - Der Dreh- und Angelpunkt

**Status**: Conversational Intelligence Core implementiert  
**Kritikalität**: ZENTRALE KOMPONENTE - alle anderen Module bauen darauf auf

#### Architektur & Datenhaltung

**Dual-Database Architecture**:
- **Transaktionale DB (PostgreSQL)**: 
  - Strukturierte Projektdaten, Kundendaten, Conversation History
  - ACID-Compliance für Geschäftskritische Transaktionen
  - Event Store für vollständige Audit-Trail
  - Relationale Integrität für Stammdaten

- **Vektor DB (pgvector/Pinecone)**:
  - Semantische Projekt-Ähnlichkeitssuche
  - Conversational Embeddings für Pattern Learning
  - Kostenmuster-Matching über historische Projekte
  - RAG-Pipeline für kontextuelle Antworten

#### Aggregations-Ebenen (Zoom-In/Zoom-Out)

**Level 1: Kostenschätzung** (Grobe Orientierung)
- **Granularität**: Gewerke-Ebene (Bad, Küche, Fassade)
- **Genauigkeit**: ±30% Toleranz
- **Datenquelle**: Vektor-Similarity zu ähnlichen Projekten
- **Output**: "Ihre Badsanierung kostet zwischen 15.000€ und 25.000€"
- **Konversationstiefe**: 3-5 Fragen

**Level 2: Kostenvoranschlag** (Detaillierte Kalkulation)
- **Granularität**: Einzelpositionen (Fliesen, Sanitär, Elektro)
- **Genauigkeit**: ±10% Toleranz
- **Datenquelle**: Transaktionale DB + Handwerker-Preisdatenbank
- **Output**: Strukturierter KVA mit 50+ Einzelpositionen
- **Konversationstiefe**: 15-20 Fragen oder Form-Completion

**Level 3: Angebot** (Verbindliches Dokument)
- **Granularität**: Rechtssichere Leistungsbeschreibung
- **Genauigkeit**: Festpreis oder definierte Variable
- **Datenquelle**: Vollständige Projektspezifikation + Handwerker-Commits
- **Output**: PDF mit AGBs, Zahlungsplan, Zeitschiene
- **Konversationstiefe**: Vollständige Spezifikation erforderlich

#### Intelligente Daten-Orchestrierung

**Write Path** (Neue Schätzung):
1. Konversation → NLU Entity Extraction
2. Entities → Transaktionale DB (strukturiert speichern)
3. Conversation → Embedding → Vektor DB (für zukünftige Similarity)
4. Generiertes Dokument → Event Bus (für andere Module)

**Read Path** (Schätzungsanfrage):
1. Query → Embedding → Vektor-Suche (ähnliche Projekte finden)
2. Top-K Results → Transaktionale DB Join (Details laden)
3. Aggregation + Adjustments (Regional, Temporal, Material)
4. Confidence Score Berechnung
5. Adaptive Response (je nach Confidence mehr/weniger Details)

#### Learning & Evolution

**Pattern Extraction Pipeline**:
- Erfolgreiche Schätzungen (Ist = Soll ±5%) → Pattern Store
- Fehlgeschlagene Schätzungen → Negative Pattern Store
- Conversation Flows → Optimal Question Sequence Learning
- User Corrections → Validation Rule Updates

**Feedback Integration**:
- Handwerker-Feedback nach Projektabschluss
- Tatsächliche Kosten vs. Schätzung
- Kundenänderungen während Projekt
- Marktpreis-Updates (Material, Lohn)

#### Integration Points

**Als Event Producer**:
- `estimation.created` → Trigger für FörderMatrix
- `estimation.detailed` → Trigger für HandwerkerNetwork
- `estimation.accepted` → Trigger für ProjectManager

**Als Event Consumer**:
- `vision.damage_detected` → Kosten-Adjustment
- `craftsman.price_updated` → Neuberechnung
- `funding.approved` → Finanzierungshinweis

**Key Innovation**: 
- **Conversation-First**: Natürlicher Dialog statt Formular-Pingpong
- **Adaptive Granularity**: Automatisches Zoom-In bei höherem User-Interest
- **Continuous Learning**: Jede Interaktion verbessert zukünftige Schätzungen
- **Fallback Intelligence**: Forms lernen optimale Feld-Reihenfolge aus Konversationen

**Standalone Value**: 
Sofort nutzbare Kostenschätzung ohne andere Module - aber jede Schätzung wird zum Grundstein für alle Folgeprozesse

**Platform Integration**: 
Die EstimationEngine ist das schlagende Herz der Plattform - ohne valide Kostenschätzung können keine Förderanträge, keine Handwerker-Beauftragungen und keine Finanzierungen erfolgen.

### FörderMatrix (Planned)
**Status**: Architektur definiert  
**Standalone Value**: Fördermittel-Optimierung mit Antragsstellung  
**Platform Integration**: Konsumiert EstimationEngine-Events, triggert DocumentGenerator  
**Key Innovation**: Einfache Orchestrierung statt komplexe Optimierung
**Fallback Strategy**: Strukturierter Förder-Wizard wenn Agent unavailable

### HandwerkerNetwork (Conceptual)
**Status**: Requirements-Gathering  
**Standalone Value**: Handwerker-Matching und Scheduling  
**Platform Integration**: Bidirektionale Events mit allen Modulen  
**Key Innovation**: Reputation-System mit Feedback-Loops
**Fallback Strategy**: Klassische Filter-Suche mit Kalenderbuchung

### VisionAnalyzer (Research)
**Status**: Proof-of-Concept  
**Standalone Value**: Bauschäden-Erkennung aus Fotos  
**Platform Integration**: Enrichment für EstimationEngine  
**Key Innovation**: Direkte Schadens-zu-Kosten Mapping
**Fallback Strategy**: Manuelle Schadens-Checkliste mit Foto-Upload

## Technical Foundation

### Data Architecture Strategy

#### Dual-Database Pattern
**Warum zwei Datenbanken?** Die Natur der Daten erfordert unterschiedliche Optimierungen:

**PostgreSQL (Transaktional)**:
- **Was**: Strukturierte Geschäftsdaten, Verträge, User-Accounts
- **Warum**: ACID-Garantien für kritische Transaktionen
- **Schema**: Normalisiert für Konsistenz
- **Performance**: Optimiert für Writes und Point-Queries

**pgvector/Pinecone (Vektoral)**:
- **Was**: Embeddings von Projekten, Konversationen, Dokumenten
- **Warum**: Similarity Search für "ähnliche Projekte finden"
- **Schema**: Hochdimensionale Vektoren (1536 Dimensionen)
- **Performance**: Optimiert für Nearest-Neighbor-Suche

#### Data Flow & Synchronisation
```
User Input → Both Databases (Different Representations)
├─ PostgreSQL: Strukturierte Entities
└─ Vector DB: Semantic Embeddings

Query → Vector Search First → PostgreSQL Enrichment
├─ Find Similar (Vector)
└─ Get Details (PostgreSQL)
```

### Current Stack
- **Claude Code SDK**: Bereits im Einsatz für Agent-Development
- **Event Bus**: Apache Pulsar (vorbereitet, noch nicht aktiv)
- **State Management**: Event Sourcing mit PostgreSQL
- **Knowledge Graph**: Neo4j für Relationship-Mapping

### Critical Architectural Decisions

#### Adaptive Form Learning System
Die Forms sind nicht statisch, sondern evolvieren:
- **Pattern Extraction**: Erfolgreiche Konversationen werden analysiert
- **Field Optimization**: Häufig gefragte Informationen werden zu Form-Feldern
- **Order Adaptation**: Reihenfolge basiert auf natürlichen Konversationsflüssen
- **Validation Rules**: Lernen aus Agent-Korrekturen und User-Feedback
- **Context Sensitivity**: Forms passen sich an User-Typ und Projekt-Kontext an

#### Event-Driven from Day One
Auch wenn Module initial standalone laufen:
- Jede User-Aktion erzeugt Events
- Events werden lokal gespeichert und können replayed werden
- Schema Registry von Anfang an (auch wenn nur ein Consumer)
- Zukünftige Orchestration ohne Breaking Changes möglich

#### Claude Code SDK Investment
Strategische Entscheidung für Claude Code SDK weil:
- Nächste Iteration wird native Sub-Agent-Unterstützung haben
- Perfektes Tooling für Multi-Agent-Development
- MCP (Model Context Protocol) als Standard für Tool-Integration
- Entwicklungsgeschwindigkeit 10x vs traditionelle Approaches

#### Infrastructure Agnosticism
Module müssen in verschiedenen Umgebungen laufen:
- **Development**: Lokal mit Docker
- **MVP**: Serverless Functions
- **Scale**: Kubernetes Pods
- **Enterprise**: On-Premise Deployment

## Platform Orchestration Vision (Future State)

### Multi-Agent Choreography
Die finale Vision (noch nicht implementiert):
```
User Intent → Primary Agent → Event Storm → Multiple Agents → Aggregated Result
```

### Warum noch nicht vollständig definiert?
- Multi-Agent-Orchestration Patterns entwickeln sich rapide
- Wir warten auf Claude Code SDK Sub-Agent Features
- Praktische Erfahrungen aus Standalone-Modulen informieren Design
- Vermeidung von premature optimization

## Development Philosophy

### Conversation-First mit Pragmatic Fallbacks
**Kernprinzip**: Jedes Modul bietet primär natürliche Konversation, aber IMMER mit robustem Fallback:
- **Adaptive Forms**: Lernen kontinuierlich aus erfolgreichen Konversationen
- **User Choice**: Nutzer können jederzeit zwischen Konversation und Form wechseln
- **Offline Capability**: Forms funktionieren auch ohne Agent-Verfügbarkeit
- **Voice Integration**: Spracheingabe kann Forms prefill oder Konversation starten
- **Progressive Enhancement**: Form-Felder werden basierend auf Konversations-Patterns optimiert

### Graduelle Intelligente Implementation
1. **Jetzt**: Module mit Event-Interfaces bauen
2. **Bald**: Punkt-zu-Punkt Integration zwischen Modulen
3. **Später**: Vollständige Multi-Agent-Orchestration
4. **Zukunft**: Self-Organizing Agent Networks

### Prinzipien für jede Entscheidung
- **Simplicity First**: Einfach bedeutet eine Verantwortung, nicht "leicht zu verstehen"
- **Events über APIs**: Lose Kopplung von Anfang an
- **Platform-Native Thinking**: Auch wenn es erstmal nur ein Modul ist
- **User Value Today**: Jedes Modul muss standalone Wert liefern
- **Always Available**: Conversation-First aber mit robusten Fallbacks für 100% Verfügbarkeit

## Current State & Next Steps

### Was funktioniert bereits
- EstimationEngine Conversational Core
- Event Schema Definition
- Domain Model (30+ Jahre Sanierungserfahrung kodifiziert)
- Claude Code SDK Integration

### Aktive Entwicklung
- EstimationEngine Knowledge Graph Integration
- FörderMatrix MVP
- Event Bus Activation
- Multi-Tenant Isolation

### Offene Forschungsfragen
- Optimale Agent-Orchestration Patterns
- Inter-Agent Negotiation Protocols
- Distributed State Consistency
- Real-time vs Eventual Consistency Trade-offs

## Wichtige Kontextinformationen

### Stakeholder Ecosystem
Die Plattform muss gleichzeitig bedienen:
- **Endkunden**: Wollen schnelle, präzise Kostenschätzungen
- **Handwerker**: Brauchen qualifizierte Leads und klare Aufträge
- **Energieberater**: Müssen Compliance sicherstellen
- **Makler**: Wollen Immobilienwert steigern
- **Banken**: Brauchen Kredit-Unterlagen

### Regulatorischer Kontext
- KfW-Förderprogramme ändern sich quartalsweise
- BAFA-Richtlinien sind komplex und regional unterschiedlich
- EnEV-Compliance ist mandatory
- Datenschutz nach DSGVO

### Markt-Realität & EstimationEngine als Game-Changer

Die EstimationEngine adressiert das Kernproblem des Marktes:
- **Problem**: Kunden brauchen 3-6 Wochen für belastbare Kostenschätzungen
- **Lösung**: 3 Minuten für Grobschätzung, 15 Minuten für Kostenvoranschlag
- **Impact**: 1000x Geschwindigkeitsvorteil bei initialer Kundeninteraktion

Die drei Aggregationsebenen entsprechen realen Geschäftsprozessen:
1. **Kostenschätzung**: Erstberatung, Finanzierungsprüfung
2. **Kostenvoranschlag**: Förderantrag, Handwerkerauswahl  
3. **Angebot**: Vertragsabschluss, Projektstart

Jede Ebene hat unterschiedliche rechtliche und geschäftliche Implikationen - die EstimationEngine versteht diese Nuancen.

## Technische Constraints & Decisions

### Was wir NICHT bauen
- Keine monolithische All-in-One Lösung
- Keine synchrone Request-Response Architektur
- Keine starren Workflows
- Keine proprietären Protokolle

### Was wir bewusst akzeptieren
- Eventual Consistency zwischen Modulen
- Höhere initiale Komplexität für Skalierbarkeit
- Bleeding-Edge Technology Risk
- Längere Time-to-first-Module für Platform-Readiness
- Dual-Database Complexity für optimale Performance

### Technische Umsetzung der Aggregations-Ebenen

**Dynamic Zoom Architecture**:
```python
# Pseudo-Code zur Verdeutlichung
class EstimationAggregator:
    def estimate_level_1(project):
        # Vektor-Suche: Top 20 ähnliche Projekte
        similar = vector_db.search(project.embedding, k=20)
        # Statistisches Modell über Similar Projects
        return aggregate_with_confidence(similar)
    
    def estimate_level_2(project):
        # Detaillierte Position aus PostgreSQL
        positions = postgres.get_standard_positions(project.type)
        # Preise aus Handwerker-Netzwerk
        prices = craftsman_network.get_current_prices(positions)
        # ML-Adjustment basierend auf Projekt-Specifics
        return detailed_calculation(positions, prices, project.specifics)
    
    def estimate_level_3(project):
        # Vollständige Spezifikation erforderlich
        spec = postgres.get_complete_specification(project.id)
        # Verbindliche Handwerker-Zusagen
        commits = craftsman_network.get_binding_commitments(spec)
        # Rechtssichere Dokumentenerzeugung
        return generate_legal_offer(spec, commits)
```

Die EstimationEngine entscheidet intelligent, wann mehr Detail nötig ist basierend auf:
- User Intent (schnelle Info vs. Projektplanung)
- Verfügbare Daten (wenig Input → Level 1, viel Input → Level 2/3)
- Confidence Score (niedrig → mehr Fragen stellen)
- Business Context (Banktermin → Level 2 needed)

## Evolution Markers

### Q1 2026
- EstimationEngine produktiv mit allen 3 Aggregations-Levels
- 100 Beta-User validieren Schätzgenauigkeit
- Dual-Database Architecture voll implementiert
- Event Bus aktiv für EstimationEngine Events

### Q2 2026
- 5 Module mit Basic Orchestration
- 1000 User
- Claude Code SDK Sub-Agents

### Q4 2026
- Full Multi-Agent Platform
- 10000+ concurrent users
- Self-improving through feedback loops

---

**Remember**: Wir bauen keine Features. Wir bauen eine Plattform, die Features baut.  
**Remember**: Jedes Modul heute ist ein Agent morgen.  
**Remember**: Events sind die DNA der Plattform - auch wenn noch niemand zuhört.
**Remember**: Die EstimationEngine ist das Fundament - ohne valide Kostendaten keine valide Plattform.