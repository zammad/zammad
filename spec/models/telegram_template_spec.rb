# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TelegramTemplate, type: :model do
  describe 'validations' do
    it 'requires a name' do
      template = build(:telegram_template, name: nil)
      expect(template).not_to be_valid
      expect(template.errors[:name]).to be_present
    end

    it 'requires unique name' do
      create(:telegram_template, name: 'Test Template')
      duplicate = build(:telegram_template, name: 'Test Template')
      expect(duplicate).not_to be_valid
    end

    it 'requires content' do
      template = build(:telegram_template, content: nil)
      expect(template).not_to be_valid
      expect(template.errors[:content]).to be_present
    end

    it 'validates parse_mode values' do
      template = build(:telegram_template, parse_mode: 'InvalidMode')
      expect(template).not_to be_valid

      %w[Markdown MarkdownV2 HTML].each do |mode|
        template.parse_mode = mode
        expect(template).to be_valid
      end
    end
  end

  describe '#render' do
    let(:group) { create(:group, name: 'Support Team') }
    let(:customer) { create(:customer, firstname: 'John', lastname: 'Doe') }
    let(:agent) { create(:agent, firstname: 'Jane', lastname: 'Smith') }
    let(:ticket) { create(:ticket, group: group, customer: customer, title: 'Test Issue') }
    let(:article) { create(:ticket_article, ticket: ticket, created_by: agent) }

    it 'renders template with ticket variables' do
      template = create(
        :telegram_template,
        content: 'Ticket #{{ticket.number}}: {{ticket.title}}'
      )

      result = template.render(article: article)
      expect(result).to eq("Ticket ##{ticket.number}: Test Issue")
    end

    it 'renders template with customer variables' do
      template = create(
        :telegram_template,
        content: 'Hello {{customer.firstname}} {{customer.lastname}} ({{customer.fullname}})'
      )

      result = template.render(article: article)
      expect(result).to eq('Hello John Doe (John Doe)')
    end

    it 'renders template with agent variables' do
      template = create(
        :telegram_template,
        content: 'Reply from {{agent.firstname}} {{agent.lastname}}'
      )

      result = template.render(article: article)
      expect(result).to eq('Reply from Jane Smith')
    end

    it 'renders template with group variables' do
      template = create(
        :telegram_template,
        content: 'Handled by {{group.name}}'
      )

      result = template.render(article: article)
      expect(result).to eq('Handled by Support Team')
    end

    it 'truncates content to 4096 characters' do
      long_content = 'A' * 5000
      template = create(:telegram_template, content: long_content)

      result = template.render(article: article)
      expect(result.length).to eq(4096)
    end
  end

  describe '#build_inline_keyboard' do
    it 'returns nil when no buttons defined' do
      template = create(:telegram_template, keyboard_buttons: [])
      expect(template.build_inline_keyboard).to be_nil
    end

    it 'builds inline keyboard from buttons' do
      buttons = [
        [
          { text: 'Yes', callback_data: 'yes' },
          { text: 'No', callback_data: 'no' }
        ],
        [
          { text: 'More Info', url: 'https://example.com' }
        ]
      ]

      template = create(:telegram_template, keyboard_buttons: buttons)
      keyboard = template.build_inline_keyboard

      expect(keyboard).to eq({ inline_keyboard: buttons })
    end
  end

  describe 'group associations' do
    it 'can be associated with groups via HasOptionalGroups' do
      group1 = create(:group)
      group2 = create(:group)

      template = create(:telegram_template)
      template.groups << [group1, group2]

      expect(template.groups).to include(group1, group2)
    end
  end
end
