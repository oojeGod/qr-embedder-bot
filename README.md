# QR Embed Telegram Bot

A Telegram bot that embeds QR codes into images.

<div align="left">
  <img src="docs/images/example.jpg" alt="Image with embedded QR code" width="600"/>
</div>

## Features

- Accepts any image from user
- Generates embedded QR code (URL, text, vCard)
- Returns image with embedded QR code that can be scanned by smartphone camera

## Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd qr_telegram_bot
   ```

2. Create `.env` file:
   ```bash
   cp .env.example .env
   ```

3. Get bot token from [@BotFather](https://t.me/botfather) and add to `.env`

## Usage

Start the bot:
```bash
docker-compose up -d
```

View logs:
```bash
docker-compose logs -f
```

Stop the bot:
```bash
docker-compose down
```

## How to Use

1. Open your bot in Telegram
2. Send `/start` command to begin
3. Upload an image
4. Choose QR code type (URL, text, or vCard)
5. Enter your data
6. Receive image with embedded QR code
7. To generate another QR code, send `/start` again

## Testing

Run tests:
```bash
docker-compose run --rm bot bundle exec rspec
```
