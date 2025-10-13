FROM ruby:3.2-slim

RUN apt-get update && apt-get install -y \
    imagemagick \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["ruby", "bin/bot"]

