# Telegram Features - Quick Reference

## Overview

Enhanced Telegram integration with templates, interactive buttons, and broadcast messaging.

## Quick Start

### 1. Create a Template

```ruby
# Via Rails console
template = TelegramTemplate.create!(
  name: 'Welcome Message',
  content: 'Hello {{customer.firstname}}! Ticket #{{ticket.number}} received by {{group.name}}.',
  parse_mode: 'Markdown',
  active: true
)
```

### 2. Add Interactive Buttons

```ruby
template.keyboard_buttons = [
  [
    { text: '📊 Check Status', callback_data: 'status' },
    { text: '❌ Cancel', callback_data: 'cancel' }
  ],
  [
    { text: '📖 Help Center', url: 'https://help.example.com' }
  ]
]
template.save!
```

### 3. Use Template in Article

```ruby
article = Ticket::Article.create!(
  ticket_id: ticket.id,
  type: Ticket::Article::Type.find_by(name: 'telegram personal-message'),
  sender: Ticket::Article::Sender.find_by(name: 'Agent'),
  body: 'Placeholder text',
  preferences: {
    telegram_template_id: template.id
  }
  # ... other required attributes
)
```

## Available Variables

| Variable | Output Example |
|----------|----------------|
| `{{ticket.number}}` | `12345` |
| `{{ticket.title}}` | `Login Issue` |
| `{{customer.firstname}}` | `John` |
| `{{customer.lastname}}` | `Doe` |
| `{{customer.fullname}}` | `John Doe` |
| `{{agent.firstname}}` | `Jane` |
| `{{agent.lastname}}` | `Smith` |
| `{{agent.fullname}}` | `Jane Smith` |
| `{{group.name}}` | `Support Team` |

## Button Types

### Callback Button
Triggers an action in Zammad when clicked:
```ruby
{ text: 'Confirm', callback_data: 'confirm_action' }
```

### URL Button
Opens a link when clicked:
```ruby
{ text: 'View Docs', url: 'https://docs.example.com' }
```

## Broadcast to Multiple Chats

```ruby
article.preferences['telegram_broadcast_chat_ids'] = [
  123456789,   # Chat ID 1
  987654321    # Chat ID 2
]
```

## Ad-hoc Keyboard (without template)

```ruby
article.preferences['telegram_keyboard'] = [
  [
    { text: 'Option A', callback_data: 'opt_a' },
    { text: 'Option B', callback_data: 'opt_b' }
  ]
]
```

## Formatting Options

### Markdown (default)
```ruby
template.parse_mode = 'Markdown'
template.content = '*bold* _italic_ [link](https://example.com)'
```

### HTML
```ruby
template.parse_mode = 'HTML'
template.content = '<b>bold</b> <i>italic</i> <a href="https://example.com">link</a>'
```

## Common Use Cases

### 1. Satisfaction Survey
```ruby
TelegramTemplate.create!(
  name: 'CSAT Survey',
  content: 'Rate your experience with ticket #{{ticket.number}}:',
  keyboard_buttons: [
    [
      { text: '⭐⭐⭐⭐⭐', callback_data: 'csat_5' },
      { text: '⭐⭐⭐⭐', callback_data: 'csat_4' }
    ],
    [
      { text: '⭐⭐⭐', callback_data: 'csat_3' },
      { text: '⭐⭐', callback_data: 'csat_2' }
    ]
  ]
)
```

### 2. Quick Actions
```ruby
TelegramTemplate.create!(
  name: 'Quick Actions',
  content: '*Ticket #{{ticket.number}}* - Available actions:',
  parse_mode: 'Markdown',
  keyboard_buttons: [
    [
      { text: '✅ Mark Resolved', callback_data: 'action_resolve' },
      { text: '⏸️ Pause', callback_data: 'action_pause' }
    ]
  ]
)
```

### 3. Group Scoped Templates
```ruby
template = TelegramTemplate.create!(
  name: 'VIP Welcome',
  content: 'Premium support activated for {{customer.fullname}}'
)
template.groups << Group.find_by(name: 'VIP Support')
```

## Handling Callback Responses

When a user clicks a button, an article is automatically created with:

```ruby
{
  body: "User pressed button: confirm_action",
  preferences: {
    telegram: {
      callback_data: "confirm_action",
      # ... other metadata
    }
  }
}
```

Create triggers or use macros to respond based on `callback_data`.

## Limitations

- Text messages: 4096 characters max (auto-truncated)
- Callback data: 64 bytes max
- Button text: Keep concise
- Broadcast errors: Logged but don't stop other sends

## Database Tables

### telegram_templates
- `name` - Unique template name
- `content` - Template text with variables
- `keyboard_buttons` - JSON array of button rows
- `parse_mode` - 'Markdown', 'MarkdownV2', or 'HTML'
- `active` - Enable/disable template

### groups_telegram_templates
Join table for group associations

## Migration

```bash
rails db:migrate
```

This creates the `telegram_templates` table and join table.

## Testing

```bash
# Run template specs
bundle exec rspec spec/models/telegram_template_spec.rb

# Create test template
template = FactoryBot.create(:telegram_template)
```

## Full Documentation

See [`doc/telegram_templates_and_engagement.md`](telegram_templates_and_engagement.md) for:
- Complete API reference
- Advanced examples
- Architecture details
- Troubleshooting

## Support

For issues specific to these Telegram enhancements, please check:
1. Template is `active: true`
2. Variables match available fields
3. Callback data is under 64 bytes
4. Parse mode is valid
5. Keyboard buttons are properly formatted JSON

---

**Added in**: Community Fork Enhancement (2025-11-30)
**Compatibility**: Zammad 7.0.x
**License**: AGPL 3.0
