# QR Telegram Bot

A Telegram bot that embeds invisible QR codes into images.

## Features

- Accepts any image from user
- Generates hidden QR code (URL, text, vCard)
- Returns image with invisible QR code that can be scanned by smartphone camera

## Installation

1. Install dependencies:
   ```bash
   bundle install
   ```

2. Copy environment file:
   ```bash
   cp .env.example .env
   ```

3. Get bot token from [@BotFather](https://t.me/botfather) and add to `.env`

4. Install ImageMagick (required for image processing):

   **macOS:**
   ```bash
   brew install imagemagick
   ```

   **Linux:**
   ```bash
   sudo apt-get install imagemagick
   ```

5. Run the bot:
   ```bash
   bundle exec ruby bin/bot
   ```

## Testing

Run tests:
```bash
bundle exec rspec
```
