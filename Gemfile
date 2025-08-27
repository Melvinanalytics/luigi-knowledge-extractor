source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.0"

# Rails Framework & Core
gem "rails", "~> 7.1"

gem "pg", "~> 1.1"
gem "image_processing", "~> 1.2"
gem "bootsnap", require: false

# Server & Performance
gem "puma", "~> 6.0"
gem "redis", "~> 5.0"
gem "hiredis"
gem "kredis"

# Frontend & JavaScript
gem "turbo-rails"
gem "stimulus-rails" 
gem "jbuilder"
gem "sassc-rails"
gem "view_component"


# Background Processing
gem "sidekiq", "~> 7.0"

# Knowledge Graph & AI
gem "activegraph" 
gem "ruby-openai"
gem "pgvector"

# Business Logic & Validation
gem "dry-validation"
gem "dry-monads"

# Authentication & Security
gem "bcrypt", "~> 3.1.7"

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "rspec-rails"
  gem "factory_bot_rails"
end

group :development do
  gem "web-console"
  gem "annotate"
  gem "bullet"
end

group :production do
  # gem "dockerfile-rails"
end