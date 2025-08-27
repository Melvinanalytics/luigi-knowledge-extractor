# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.3.0
FROM ruby:$RUBY_VERSION-slim as base

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_WITHOUT="development:test"

# Install packages needed to build gems and run the application
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    curl \
    libpq-dev \
    libvips \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and Yarn for assets
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# Copy application code
COPY . .

# Install Ruby dependencies
RUN bundle install

# Install JavaScript dependencies
RUN yarn install --frozen-lockfile

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets for production (Railway handles this automatically)
# RUN SECRET_KEY_BASE=DUMMY REDIS_URL=redis://localhost:6379/0 OPENAI_API_KEY=dummy PRECOMPILING_ASSETS=1 bundle exec rails assets:precompile

# Clean up build dependencies
RUN apt-get remove --purge -y build-essential git && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create a non-root user and required directories
RUN useradd rails --create-home --shell /bin/bash && \
    mkdir -p log storage tmp && \
    chown -R rails:rails db log storage tmp
USER rails:rails

# Entrypoint prepares the database
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default
EXPOSE 3000
CMD ["./bin/rails", "server"]