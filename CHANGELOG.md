# Change Log for Zammad 7.0.x

- [Release notes](https://zammad.com/en/releases/7-0-x)
- [Breaking changes](BREAKING_CHANGES.md#70)
- [Implemented enhancements](https://github.com/zammad/zammad/issues?q=is%3Aclosed+milestone%3A7.0+(-type%3ABug+AND+-label%3Abug))
- [Closed bugs](https://github.com/zammad/zammad/issues?q=is%3Aclosed+milestone%3A7.0+(type%3ABug+OR+label%3Abug))
- [Full commit log](https://github.com/zammad/zammad/compare/6.5.1...7.0.x)
- [File tree](https://github.com/zammad/zammad/tree/7.0.x)

## Community Enhancements - Fork Specific

### Telegram Integration Enhancements (2025-11-30)

**Feature: Telegram Template Scripts and Group Engagement**

This release adds comprehensive template and interactive engagement capabilities to the Telegram integration.

#### New Features

**Template System:**
- Added `TelegramTemplate` model with dynamic variable substitution
- Support for template variables: `{{ticket.*}}`, `{{customer.*}}`, `{{agent.*}}`, `{{group.*}}`
- Group-scoped templates using `HasOptionalGroups` concern
- Multiple parse modes: Markdown, MarkdownV2, HTML
- Automatic content truncation to Telegram's 4096 character limit

**Interactive Buttons & Group Engagement:**
- Inline keyboard support for interactive message buttons
- Callback query handling for button click events
- Two button types supported:
  - Callback buttons (trigger in-app actions)
  - URL buttons (open external links)
- Ad-hoc keyboard support via article preferences

**Broadcast Messaging:**
- Multi-recipient message broadcasting
- Send to multiple Telegram chats simultaneously
- Graceful error handling per recipient
- Ideal for group announcements and notifications

#### Technical Changes

**New Files:**
- `app/models/telegram_template.rb` - Template model with rendering engine
- `db/migrate/20251130000001_create_telegram_templates.rb` - Database schema
- `spec/models/telegram_template_spec.rb` - Comprehensive test coverage
- `spec/factories/telegram_template.rb` - Test factories
- `doc/telegram_templates_and_engagement.md` - Complete feature documentation

**Enhanced Files:**
- `app/jobs/communicate_telegram_job.rb` - Template rendering, keyboard support, broadcasts
- `lib/telegram_helper.rb` - Callback query handler (67 lines added)

#### Use Cases

- **Satisfaction Surveys**: Interactive emoji-based customer feedback
- **Quick Action Menus**: One-tap ticket actions (status, resolve, pause)
- **Multi-group Announcements**: Broadcast system messages
- **Interactive Workflows**: Button-driven customer journeys

#### Migration Required

After updating, run:
```bash
rails db:migrate
```

#### Documentation

See `doc/telegram_templates_and_engagement.md` for:
- Complete API reference
- Variable substitution guide
- Usage examples and patterns
- Technical notes and limitations

#### Backward Compatibility

✅ This is a fully backward-compatible enhancement. Existing Telegram functionality remains unchanged.
