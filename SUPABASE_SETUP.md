# 🚀 Luigi Knowledge Extractor - Supabase Setup Guide

This guide will help you configure Supabase for the Luigi Knowledge Extractor application.

## 📋 Prerequisites

1. A Supabase account (sign up at [supabase.com](https://supabase.com))
2. Docker and Docker Compose installed
3. The Luigi Knowledge Extractor codebase

## 🔧 Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign in
2. Click "New Project"
3. Choose your organization
4. Enter project details:
   - **Name**: `luigi-knowledge-extractor`
   - **Database Password**: Choose a strong password
   - **Region**: Select closest to your location
5. Click "Create new project"
6. Wait for the project to initialize (2-3 minutes)

## 🔑 Step 2: Get Your Credentials

Once your project is ready, go to **Settings > API**:

1. **Project URL** - Copy the URL (starts with `https://`)
2. **API Keys**:
   - **anon/public key** - Copy this
   - **service_role/secret key** - Copy this (keep it secret!)

Go to **Settings > Database**:

3. **Connection String** - Copy the URI format connection string

## 🛠️ Step 3: Configure Environment Variables

Update your `.env` file with your Supabase credentials:

```bash
# Supabase Configuration
DATABASE_URL=postgresql://postgres.xyz:[PASSWORD]@aws-0-eu-central-1.pooler.supabase.com:6543/postgres
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# OpenAI API Configuration (get from OpenAI dashboard)
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_ORGANIZATION_ID=your_org_id_here
```

**Important Notes:**
- Replace `[PASSWORD]` in DATABASE_URL with your actual database password
- Replace `your-project-id` with your actual project ID
- Keep your service role key secure - never commit it to version control

## 🚀 Step 4: Start the Application

1. **Stop any running containers:**
   ```bash
   docker-compose down
   ```

2. **Start the services:**
   ```bash
   docker-compose up -d redis neo4j
   docker-compose up luigi-app
   ```

3. **Run database migrations:**
   ```bash
   docker-compose exec luigi-app bundle exec rails db:migrate
   ```

4. **Initialize Luigi expert data:**
   ```bash
   docker-compose exec luigi-app bundle exec rails runner "LuigiExpert.luigi"
   ```

## 🧪 Step 5: Test the Application

1. Open your browser and go to `http://localhost:3333`
2. You should see the Luigi Knowledge Extractor interface
3. Try sending a message to test the AI integration

## 🔍 Verification Checklist

- [ ] Supabase project created and initialized
- [ ] All environment variables configured in `.env`
- [ ] Application starts without database connection errors
- [ ] Migrations run successfully
- [ ] Luigi expert initialized
- [ ] Web interface loads at localhost:3333
- [ ] Neo4j accessible (check `http://localhost:7475`)
- [ ] Redis running (no need to check directly)

## 🛠️ Supabase Database Features

Your Supabase database includes:

- **pgvector extension** - For AI embeddings
- **UUID extension** - For unique identifiers
- **Row Level Security** - For data protection
- **Real-time subscriptions** - For live updates
- **Edge Functions** - For serverless functions
- **Storage** - For file uploads

## 📊 Monitoring

- **Supabase Dashboard**: Monitor database usage, API calls
- **Logs**: Check `docker-compose logs luigi-app` for application logs
- **Database**: Use Supabase SQL Editor for direct database access

## 🚨 Troubleshooting

### Database Connection Issues
```bash
# Check if DATABASE_URL is correct
docker-compose exec luigi-app rails runner "puts ActiveRecord::Base.connection.execute('SELECT version();').first"
```

### Missing Extensions
If you get pgvector errors:
```sql
-- Run in Supabase SQL Editor:
CREATE EXTENSION IF NOT EXISTS vector;
```

### Migration Issues
```bash
# Reset database if needed
docker-compose exec luigi-app rails db:drop db:create db:migrate
```

## 📈 Next Steps

Once everything is working:

1. **Configure OpenAI API** for knowledge extraction
2. **Set up real-time features** using Action Cable
3. **Enable Row Level Security** in Supabase
4. **Add authentication** if needed
5. **Deploy to production** (Heroku, Railway, etc.)

## 🆘 Need Help?

- **Supabase Docs**: [supabase.com/docs](https://supabase.com/docs)
- **Rails Guides**: [guides.rubyonrails.org](https://guides.rubyonrails.org)
- **Check logs**: `docker-compose logs luigi-app`

---

**🎯 Ready to extract knowledge from Luigi's 30+ years of construction experience!**