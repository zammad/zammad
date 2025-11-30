# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TelegramTemplate < ApplicationModel
  include HasDefaultModelUserRelations
  include ChecksClientNotification
  include ChecksHtmlSanitized
  include HasOptionalGroups

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :content, presence: true
  validates :parse_mode, inclusion: { in: %w[Markdown MarkdownV2 HTML], allow_nil: true }

  validates :note, length: { maximum: 250 }
  sanitized_html :note

  store :keyboard_buttons

  # Render template with variable substitution
  # Supported variables:
  #   {{ticket.number}} - Ticket number
  #   {{ticket.title}} - Ticket title
  #   {{customer.firstname}} - Customer first name
  #   {{customer.lastname}} - Customer last name
  #   {{customer.fullname}} - Customer full name
  #   {{agent.firstname}} - Agent first name
  #   {{agent.lastname}} - Agent last name
  #   {{agent.fullname}} - Agent full name
  #   {{group.name}} - Group name
  def render(article:)
    ticket = article.ticket
    customer = ticket.customer
    agent = article.created_by
    group = ticket.group

    rendered_content = content.dup

    # Ticket variables
    rendered_content.gsub!('{{ticket.number}}', ticket.number.to_s)
    rendered_content.gsub!('{{ticket.title}}', ticket.title.to_s)

    # Customer variables
    rendered_content.gsub!('{{customer.firstname}}', customer.firstname.to_s)
    rendered_content.gsub!('{{customer.lastname}}', customer.lastname.to_s)
    rendered_content.gsub!('{{customer.fullname}}', customer.fullname.to_s)

    # Agent variables
    rendered_content.gsub!('{{agent.firstname}}', agent.firstname.to_s)
    rendered_content.gsub!('{{agent.lastname}}', agent.lastname.to_s)
    rendered_content.gsub!('{{agent.fullname}}', agent.fullname.to_s)

    # Group variables
    rendered_content.gsub!('{{group.name}}', group.name.to_s)

    # Telegram has a 4096 character limit for text messages
    rendered_content[0...4096]
  end

  # Build inline keyboard from stored buttons
  # keyboard_buttons format: [
  #   [{ text: 'Button 1', callback_data: 'action_1' }, { text: 'Button 2', callback_data: 'action_2' }],
  #   [{ text: 'Button 3', url: 'https://example.com' }]
  # ]
  def build_inline_keyboard
    return nil if keyboard_buttons.blank?

    {
      inline_keyboard: keyboard_buttons
    }
  end
end
