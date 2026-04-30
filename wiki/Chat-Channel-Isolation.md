# Chat Channel Isolation

Chat channel isolation ensures that each OpenClaw agent communicates through its own dedicated Telegram chat channel. This provides privacy, organization, and prevents cross-talk between agents.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Benefits of Isolation](#benefits-of-isolation)
3. [Creating Telegram Bots](#creating-telegram-bots)
4. [Configuring Channel Isolation](#configuring-channel-isolation)
5. [Multi-User Setup](#multi-user-setup)
6. [Channel Management](#channel-management)
7. [Troubleshooting](#troubleshooting)

---

## Overview

OpenClaw uses Telegram as its primary communication interface. With three agents (Assistant, Research, Developer), channel isolation ensures:

- Each agent has its own private chat
- Users interact with the right agent intuitively
- Conversations are organized by topic/agent
- No confusion about which agent is responding

### Architecture

```text
┌─────────────────────────────────────────────────┐
│              Telegram                           │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────┐  ┌──────────────┐            │
│  │ Assistant Bot│  │ Research Bot │  ...        │
│  │   @Chat #1   │  │   @Chat #2   │            │
│  └──────────────┘  └──────────────┘            │
│        │                │                       │
└────────┼────────────────┼───────────────────────┘
         │                │
         ▼                ▼
┌─────────────────────────────────────────────────┐
│           OpenClaw Gateway                      │
│  (Routes messages to correct agent)            │
└─────────────────────────────────────────────────┘
         │                │                │
         ▼                ▼                ▼
   ┌─────────┐      ┌─────────┐      ┌─────────┐
   │Assistant│      │Research │      │Developer│
   │ Agent   │      │ Agent   │      │ Agent   │
   └─────────┘      └─────────┘      └─────────┘
```text

---

## Benefits of Isolation

### 1. **Privacy**
- Each agent only sees messages intended for it
- User preferences stored separately per agent
- No cross-contamination of conversations

### 2. **Organization**
- Conversations grouped by agent expertise
- Easy to find past discussions
- Clear context for each agent type

### 3. **Multi-User Support**
- Multiple users can interact with the same agent
- User A's conversation with Assistant doesn't mix with User B's
- Granular permission control per channel

### 4. **Debugging**
- Isolate issues to specific agents
- Clear logs per agent/channel
- Easier troubleshooting

---

## Creating Telegram Bots

### Step 1: Contact BotFather

1. Open Telegram and search for `@BotFather`
2. Start a conversation and send `/newbot`
3. Follow the prompts:

```text
You: /newbot
BotFather: Alright, a new bot. How are we going to call it? 
           Please choose a name for your bot.

You: OpenClaw Assistant  (This is the display name)

BotFather: Good. Now let's choose a username for your bot. 
           It must end in `bot`. Like this: TetrisBot or tetris_bot.

You: openclaw_assistant_bot

BotFather: Done! Congratulations on your new bot. 
           Use this token to access the HTTP API:
           123456789:ABCdefGHIjklMNOpqrsTUVwxyz
           
           Keep your token secure and store it safely.
```text

### Step 2: Create Three Bots

Repeat the process for each agent:

| Agent | Suggested Bot Name | Username Example |
|-------|-------------------|------------------|
| Assistant | OpenClaw Assistant | `openclaw_assistant_bot` |
| Research | OpenClaw Research | `openclaw_research_bot` |
| Developer | OpenClaw Developer | `openclaw_developer_bot` |

### Step 3: Save Bot Tokens

Store the tokens securely:

```bash
# Create a file to store tokens (don't commit this!)
nano ~/telegram-bot-tokens.txt
```text

Content:

```text
Assistant Bot Token: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz
Research Bot Token: 987654321:ZYXwvuTSRqponMLKjihGFEdcba
Developer Bot Token: 111222333:AABBccDDeeFFggHHiiJJkkLLmm
```text

**⚠️ Security Warning:** Never commit bot tokens to version control!

---

## Configuring Channel Isolation

### Docker Configuration

Edit `docker-config.env`:

```bash
# Telegram Bot Tokens (one per agent)
TELEGRAM_ASSISTANT_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_RESEARCH_BOT_TOKEN=987654321:ZYXwvuTSRqponMLKjihGFEdcba
TELEGRAM_DEVELOPER_BOT_TOKEN=111222333:AABBccDDeeFFggHHiiJJkkLLmm

# Optional: Bot usernames (for display)
TELEGRAM_ASSISTANT_BOT_USERNAME=openclaw_assistant_bot
TELEGRAM_RESEARCH_BOT_USERNAME=openclaw_research_bot
TELEGRAM_DEVELOPER_BOT_USERNAME=openclaw_developer_bot
```text

### Bare Metal Configuration

Set environment variables:

```bash
export TELEGRAM_ASSISTANT_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
export TELEGRAM_RESEARCH_BOT_TOKEN="987654321:ZYXwvuTSRqponMLKjihGFEdcba"
export TELEGRAM_DEVELOPER_BOT_TOKEN="111222333:AABBccDDeeFFggHHiiJJkkLLmm"

# Add to ~/.bashrc for persistence
echo 'export TELEGRAM_ASSISTANT_BOT_TOKEN="..."' >> ~/.bashrc
```text

### Verify Configuration

```bash
# For Docker
docker compose up -d
docker compose logs -f | grep -i "telegram\|bot"

# For Bare Metal
openclaw --verify-config
```text

You should see messages like:

```text
[INFO] Telegram bot initialized: @openclaw_assistant_bot
[INFO] Telegram bot initialized: @openclaw_research_bot
[INFO] Telegram bot initialized: @openclaw_developer_bot
```text

---

## Multi-User Setup

### Adding Multiple Users to an Agent

By default, any user who knows the bot username can interact with it. To restrict access:

#### Method 1: Whitelist in Configuration

```bash
# In docker-config.env or .env
TELEGRAM_ALLOWED_USERS_ASSISTANT="12345678,87654321,11223344"
TELEGRAM_ALLOWED_USERS_RESEARCH="12345678"
TELEGRAM_ALLOWED_USERS_DEVELOPER="12345678,11223344"
```text

Get user IDs by having them send `/start` to the bot, then check logs:

```bash
docker compose logs openclaw | grep "User ID"
```text

#### Method 2: Private Channels

Create a private Telegram channel for each agent:

1. Create a new private channel in Telegram
2. Add the bot as an administrator
3. Users join the channel to interact with the agent
4. Bot only responds in that specific channel

Configuration:

```bash
TELEGRAM_ASSISTANT_CHANNEL_ID="-1001234567890"
TELEGRAM_RESEARCH_CHANNEL_ID="-1009876543210"
TELEGRAM_DEVELOPER_CHANNEL_ID="-1001122334455"
```text

### User Permissions Matrix

| User | Assistant Bot | Research Bot | Developer Bot |
|------|--------------|--------------|---------------|
| Alice | ✅ Admin | ✅ Read | ❌ No Access |
| Bob | ✅ Read/Write | ✅ Admin | ✅ Read |
| Charlie | ❌ No Access | ✅ Read | ✅ Admin |

---

## Channel Management

### Starting Conversations

Users need to initiate contact with each bot:

1. Search for the bot username (e.g., `@openclaw_assistant_bot`)
2. Send `/start` to begin
3. The bot will respond and remember the user

### Bot Commands

Configure available commands for each bot via BotFather:

```text
/setcommands

Select bot: @openclaw_assistant_bot

Commands:
start - Start interacting with Assistant
help - Show available commands
memory - View what I remember about you
clear - Clear conversation history
tasks - View your task list
```text

### Channel-Specific Settings

Customize behavior per channel:

```markdown
# In assistant/SOUL.md
## Channel-Specific Behavior

**Private Chat:**
- Respond immediately to all messages
- Use concise format for quick answers

**Group Chat:**
- Only respond when mentioned (@openclaw_assistant_bot)
- Provide detailed explanations
- Include source links when researching
```text

---

## Advanced Isolation Techniques

### 1. Topic-Based Isolation (Telegram Forums)

For Telegram Premium users, create a forum with topics:

```text
OpenClaw Central (Forum)
├── 🤖 Assistant Topic
├── 🔍 Research Topic
└── 💻 Developer Topic
```text

Add bot to the forum and configure:

```bash
TELEGRAM_FORUM_MODE=true
TELEGRAM_ASSISTANT_TOPIC_ID=1
TELEGRAM_RESEARCH_TOPIC_ID=2
TELEGRAM_DEVELOPER_TOPIC_ID=3
```text

### 2. Separate Telegram Accounts

For maximum isolation, use different Telegram accounts for each agent:

- Account 1: Personal account for Assistant
- Account 2: Work account for Research
- Account 3: Development account for Developer

This requires multiple phone numbers but provides complete separation.

### 3. Message Filtering

Implement custom message filters in agent configuration:

```markdown
# In AGENTS.md
## Message Filtering Rules

- Ignore messages containing certain keywords
- Only process messages with specific hashtags
- Forward messages from specific users to specific agents
```text

---

## Troubleshooting

### Bot Not Responding

```bash
# Check if bot token is valid
curl "https://api.telegram.org/bot<YOUR_TOKEN>/getMe"

# Should return:
# {"ok":true,"result":{"id":123456789,"is_bot":true,"first_name":"...","username":"..."}}
```text

### "Unauthorized" Error

**Cause**: Invalid bot token

**Solution**:
1. Verify token in BotFather
2. Update `docker-config.env` or environment variables
3. Restart OpenClaw

### Multiple Bots Conflicting

**Cause**: Bots receiving each other's messages

**Solution**: Ensure each bot has its own token and is configured for its specific agent:

```bash
# Verify each agent only has its own token
grep TELEGRAM_ docker-config.env
```text

### Messages Going to Wrong Agent

**Cause**: Misconfigured routing

**Solution**: Check OpenClaw Gateway configuration:

```bash
# View routing logs
docker compose logs openclaw | grep "routing\|dispatch"

# Verify agent-to-bot mapping
openclaw --show-config | grep -A 5 "telegram"
```text

### User Can't Access Bot

**Cause**: User not in whitelist or bot privacy mode

**Solution**:
1. Check whitelist configuration
2. In BotFather, disable privacy mode: `/setprivacy` → Disable
3. Ensure bot is added to the channel/group

---

## Testing Channel Isolation

### Test 1: Verify Each Bot Responds

```bash
# Send /start to each bot and verify response
# Assistant Bot → Should respond with Assistant greeting
# Research Bot → Should respond with Research greeting
# Developer Bot → Should respond with Developer greeting
```text

### Test 2: Verify Isolation

1. Send a message to Assistant Bot
2. Check that Research and Developer bots don't see it
3. Verify each agent's memory is separate

### Test 3: Multi-User Test

1. Have User A send message to Assistant
2. Have User B send message to Assistant
3. Verify both conversations are separate and isolated

---

## Best Practices

1. **Use Descriptive Bot Names**: Make it clear which agent is which
2. **Set Bot Descriptions**: Via BotFather, add descriptions like "OpenClaw Assistant - General Purpose AI Helper"
3. **Regular Token Rotation**: Periodically regenerate bot tokens for security
4. **Monitor Access Logs**: Regularly check who is accessing your bots
5. **Backup Configurations**: Keep secure backups of working configurations

---

## Security Considerations

### Protecting Bot Tokens

```bash
# Set proper permissions on config files
chmod 600 docker-config.env
chmod 600 ~/.bashrc

# Use secret management for production
# Consider: Vault, AWS Secrets Manager, etc.
```text

### Preventing Abuse

- Set rate limits per user
- Monitor for spam patterns
- Implement cooldown periods
- Log suspicious activity

### User Privacy

- Agents only store necessary information
- Users can request data deletion (`/forgetme` command)
- Regular audit of stored memories
- Comply with data protection regulations

---

## Next Steps

After setting up channel isolation:

1. Configure **[Agent Configuration](Agent-Configuration)** for each bot
2. Set up **[Lemonade Configuration](Lemonade-Configuration)** for local inference
3. Review **[Troubleshooting](Troubleshooting)** for common issues

---

## Additional Resources

- [Telegram Bot API Documentation](https://core.telegram.org/bots/api)
- [BotFather Commands](https://core.telegram.org/bots#6-botfather)
- [OpenClaw Configuration](../README.md#configuration)
- [Docker Deployment](Docker-Deployment)

---

*Last updated: April 2026*
