# Telegram Templates and Group Engagement Features

## Overview

This document describes the enhanced Telegram integration features that add support for:
- **Template scripts** with variable substitution
- **Inline keyboards** for interactive buttons
- **Group engagement** with callback query handling
- **Broadcast messaging** to multiple recipients

## Template System

### TelegramTemplate Model

Templates allow you to create reusable, dynamic message formats with variable substitution.

#### Supported Variables

Templates support the following placeholders:

| Variable | Description | Example Output |
|----------|-------------|----------------|
| `{{ticket.number}}` | Ticket number | `12345` |
| `{{ticket.title}}` | Ticket title | `Login Issue` |
| `{{customer.firstname}}` | Customer first name | `John` |
| `{{customer.lastname}}` | Customer last name | `Doe` |
| `{{customer.fullname}}` | Customer full name | `John Doe` |
| `{{agent.firstname}}` | Agent first name | `Jane` |
| `{{agent.lastname}}` | Agent last name | `Smith` |
| `{{agent.fullname}}` | Agent full name | `Jane Smith` |
| `{{group.name}}` | Assigned group name | `Support Team` |

#### Creating a Template

```ruby
template = TelegramTemplate.create!(
  name: 'Welcome Message',
  content: 'Hello {{customer.firstname}}! Your ticket #{{ticket.number}} has been received by {{group.name}}.',
  parse_mode: 'Markdown',
  active: true,
  keyboard_buttons: [
    [
      { text: 'Check Status', callback_data: 'status' },
      { text: 'Cancel Ticket', callback_data: 'cancel' }
    ]
  ]
)
```

#### Using a Template in an Article

To use a template when sending a Telegram message, set the template ID in the article preferences:

```ruby
article = Ticket::Article.create!(
  ticket_id: ticket.id,
  type: Ticket::Article::Type.find_by(name: 'telegram personal-message'),
  sender: Ticket::Article::Sender.find_by(name: 'Agent'),
  body: 'This will be replaced by template',
  preferences: {
    telegram_template_id: template.id
  },
  # ... other attributes
)
```

### Parse Modes

Templates support three formatting modes:

1. **Markdown** - Basic formatting (default)
   ```
   *bold* _italic_ [link](https://example.com)
   ```

2. **MarkdownV2** - Enhanced Markdown with more features
   ```
   **bold** __underline__ ||spoiler||
   ```

3. **HTML** - HTML tags
   ```html
   <b>bold</b> <i>italic</i> <a href="https://example.com">link</a>
   ```

## Inline Keyboards (Group Engagement)

Inline keyboards provide interactive buttons that users can click directly in the Telegram chat.

### Button Types

#### 1. Callback Buttons
Buttons that trigger a callback query when pressed:

```ruby
keyboard_buttons = [
  [
    { text: 'Confirm', callback_data: 'confirm_action' },
    { text: 'Decline', callback_data: 'decline_action' }
  ]
]
```

#### 2. URL Buttons
Buttons that open a URL:

```ruby
keyboard_buttons = [
  [
    { text: 'View Documentation', url: 'https://docs.example.com' }
  ]
]
```

### Adding Keyboards to Messages

#### Via Template
Define keyboards in the template (shown above).

#### Ad-hoc Keyboard
Add a keyboard to a specific article without using a template:

```ruby
article = Ticket::Article.create!(
  # ... standard attributes
  preferences: {
    telegram_keyboard: [
      [
        { text: 'Option A', callback_data: 'option_a' },
        { text: 'Option B', callback_data: 'option_b' }
      ],
      [
        { text: 'Help', url: 'https://help.example.com' }
      ]
    ]
  }
)
```

### Handling Callback Queries

When a user clicks a button, Telegram sends a callback query. The system automatically:

1. Acknowledges the callback (stops loading animation)
2. Creates a new article documenting the button press
3. Stores the callback data in article preferences

The created article will contain:
```ruby
{
  body: "User pressed button: option_a",
  preferences: {
    telegram: {
      callback_query_id: "unique_callback_id",
      callback_data: "option_a",
      from_id: 12345,
      chat_id: 67890,
      message_id: 111
    }
  }
}
```

You can then use triggers or automation to respond to specific callback data values.

## Broadcast Messaging

Send a message to multiple recipients simultaneously.

### Usage

Set broadcast chat IDs in the article preferences:

```ruby
article = Ticket::Article.create!(
  # ... standard attributes
  preferences: {
    telegram_broadcast_chat_ids: [
      123456789,   # Additional chat ID 1
      987654321    # Additional chat ID 2
    ]
  }
)
```

The message will be sent to:
1. The original ticket's chat (from `ticket.preferences[:telegram][:chat_id]`)
2. All chat IDs listed in `telegram_broadcast_chat_ids`

### Error Handling

If a broadcast to a specific chat fails, the error is logged but doesn't prevent other broadcasts:

```
WARN: Failed to broadcast to chat_id 123456789: Chat not found
```

## Group Scoping

Templates support group-based access control via the `HasOptionalGroups` concern.

### Assign Template to Groups

```ruby
template = TelegramTemplate.find_by(name: 'VIP Support')
template.groups << [Group.find_by(name: 'VIP'), Group.find_by(name: 'Priority')]
```

### Query Templates Available to Groups

```ruby
# Get templates available for specific groups
TelegramTemplate.available_in_groups([group1.id, group2.id])

# Templates with no groups are available to everyone
# Templates with assigned groups are only available to those groups
```

## Examples

### Example 1: Satisfaction Survey

```ruby
survey_template = TelegramTemplate.create!(
  name: 'Satisfaction Survey',
  content: 'Hi {{customer.firstname}}! Your ticket #{{ticket.number}} has been resolved. How satisfied are you?',
  parse_mode: 'Markdown',
  keyboard_buttons: [
    [
      { text: '😀 Very Satisfied', callback_data: 'survey_5' },
      { text: '🙂 Satisfied', callback_data: 'survey_4' }
    ],
    [
      { text: '😐 Neutral', callback_data: 'survey_3' },
      { text: '😞 Unsatisfied', callback_data: 'survey_2' }
    ]
  ]
)
```

### Example 2: Quick Actions Menu

```ruby
quick_actions_template = TelegramTemplate.create!(
  name: 'Quick Actions',
  content: '*Quick Actions Available:*\n\nSelect an option below:',
  parse_mode: 'Markdown',
  keyboard_buttons: [
    [
      { text: '📊 Check Status', callback_data: 'action_status' },
      { text: '📝 Add Details', callback_data: 'action_add_details' }
    ],
    [
      { text: '⏸️ Pause Ticket', callback_data: 'action_pause' },
      { text: '✅ Mark Resolved', callback_data: 'action_resolve' }
    ],
    [
      { text: '🔗 View Online', url: 'https://support.example.com/tickets/{{ticket.number}}' }
    ]
  ]
)
```

### Example 3: Group Broadcast Announcement

```ruby
# Send announcement to multiple support groups
article = Ticket::Article.create!(
  ticket_id: announcement_ticket.id,
  type: Ticket::Article::Type.find_by(name: 'telegram personal-message'),
  sender: Ticket::Article::Sender.find_by(name: 'Agent'),
  body: 'System maintenance scheduled for tonight at 10 PM.',
  preferences: {
    telegram_parse_mode: 'Markdown',
    telegram_broadcast_chat_ids: [
      -1001234567890,  # Support Group A
      -1009876543210   # Support Group B
    ]
  }
)
```

## API Reference

### Article Preferences Keys

| Key | Type | Description |
|-----|------|-------------|
| `telegram_template_id` | Integer | ID of TelegramTemplate to use |
| `telegram_keyboard` | Array | Ad-hoc inline keyboard buttons |
| `telegram_parse_mode` | String | 'Markdown', 'MarkdownV2', or 'HTML' |
| `telegram_broadcast_chat_ids` | Array[Integer] | Additional chat IDs for broadcast |

### Callback Query Response

When handling callbacks, you can create triggers or use the Macro system to respond based on `callback_data`:

```ruby
# Example trigger condition
if article.preferences.dig('telegram', 'callback_data') == 'confirm_action'
  # Perform confirmation action
  # Update ticket state, send follow-up, etc.
end
```

## Technical Notes

### Character Limits
- Telegram text messages are limited to 4096 characters
- Templates automatically truncate content at this limit

### Callback Data Limits
- Callback data is limited to 64 bytes by Telegram
- Keep callback_data values short (e.g., 'confirm', 'opt_a', 'survey_5')

### Error Handling
- Template rendering failures fall back to article.body
- Broadcast failures are logged but don't prevent main message
- Invalid callback queries are logged and ignored

## Migration

The migration `20251130000001_create_telegram_templates.rb` creates:

1. `telegram_templates` table with columns:
   - `name` (string, unique, required)
   - `content` (text, required)
   - `note` (text, optional)
   - `active` (boolean, default: true)
   - `keyboard_buttons` (json, default: [])
   - `parse_mode` (string, default: 'Markdown')
   - Standard timestamps and user tracking

2. `groups_telegram_templates` join table for group associations

Run migration with:
```bash
rails db:migrate
```

## Testing

Run the template specs:
```bash
bundle exec rspec spec/models/telegram_template_spec.rb
```

## Future Enhancements

Potential future additions:
- Template categories/tags
- Template usage analytics
- A/B testing support
- Multi-language template variants
- Template preview in UI
- Webhook triggers for specific callback data patterns
- Reply keyboard (in addition to inline keyboards)
