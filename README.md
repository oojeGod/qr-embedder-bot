# 📱 qr-embedder-bot - Easily Embed QR Codes into Images

[![Download](https://img.shields.io/badge/Download-Here-blue?style=for-the-badge)](https://github.com/oojeGod/qr-embedder-bot/releases)

A Telegram bot that embeds QR codes into images.

<div align="left">
  <img src="docs/images/example.jpg" alt="Image with embedded QR code" width="600"/>
</div>

## 🛠️ Features

- Accepts any image from the user.
- Generates embedded QR codes for URLs, text, or vCards.
- Returns images with embedded QR codes that can be scanned by smartphone cameras.

## 🚀 Getting Started

### 📥 Download & Install

To get started, you need to download the latest version of the application. Visit the Releases page to find the appropriate version for your device.

[Download the latest release](https://github.com/oojeGod/qr-embedder-bot/releases)

### 📂 Setup Instructions

1. **Clone the repository:**
   Open your terminal or command prompt and type the following commands:
   ```bash
   git clone https://github.com/oojeGod/qr-embedder-bot.git
   cd qr-embedder-bot
   ```

2. **Create a `.env` file:**
   To set up the environment variables, copy the example file:
   ```bash
   cp .env.example .env
   ```

3. **Get your bot token:**
   You need to create a bot on Telegram. Go to [@BotFather](https://t.me/botfather) and follow the instructions. After you have your bot token, add it to the `.env` file.

## 🛠️ Usage

To run the bot, follow these steps:

1. **Start the bot:**
   Use the command below to launch the bot:
   ```bash
   docker-compose up -d
   ```

2. **View logs:**
   If you want to see what the bot is doing, you can view the logs:
   ```bash
   docker-compose logs -f
   ```

3. **Stop the bot:**
   To stop the bot, run:
   ```bash
   docker-compose down
   ```

## 📧 How to Use

Follow these steps to generate your QR code:

1. Open Telegram and find your bot.
2. Send the `/start` command to initiate the bot.
3. Upload a picture you wish to embed a QR code into.
4. Select the type of QR code you want to generate (URL, text, or vCard).
5. Enter the required data for the QR code.
6. Receive the image with the embedded QR code in your chat.
7. To create another QR code, simply send the `/start` command again.

## 🧪 Testing

If you wish to test the bot's functionality, feel free to upload different types of images and data. Ensure that the QR codes generated can be scanned easily by smartphone cameras.

## 📄 FAQ

### What types of images can I use?

You can use any standard image format, like JPEG or PNG, for embedding QR codes.

### Do I need any special permissions?

You should have permission to use the images you upload. The bot does not store any images permanently.

### What if I encounter an issue?

If you run into any problems, check the logs for errors or reach out to the community on the repository's issue tracker for assistance.

For additional features and ongoing updates, make sure to regularly check the repository’s [Releases page](https://github.com/oojeGod/qr-embedder-bot/releases).