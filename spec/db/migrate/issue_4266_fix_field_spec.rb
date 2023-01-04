# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4266FixField, type: :db_migration do

  context 'when config is migrated' do
    before do
      Setting.find_by(name: 'customer_ticket_create_group_ids').destroy
      Setting.create_if_not_exists(
        title:       'Group selection for Ticket creation',
        name:        'customer_ticket_create_group_ids',
        area:        'CustomerWeb::Base',
        description: 'Defines groups for which a customer can create tickets via web interface. "-" means all groups are available.',
        options:     {
          form: [
            {
              display:    '',
              null:       true,
              name:       'group_ids',
              tag:        'select',
              multiple:   true,
              nulloption: true,
              relation:   'Group',
            },
          ],
        },
        state:       '',
        preferences: {
          authentication: true,
          permission:     ['admin.channel_web'],
        },
        frontend:    true
      )

      migrate
    end

    it 'does change the config properly', :aggregate_failures do
      setting = Setting.find_by(name: 'customer_ticket_create_group_ids')
      expect(setting.options['form'][0]['tag']).to eq('multiselect')
      expect(setting.options['form'][0]['nulloption']).to be_nil
    end
  end

  context 'when value is correct' do
    let(:setting_value) { [Group.first.id] }

    before do
      Setting.set('customer_ticket_create_group_ids', setting_value)
      migrate
    end

    it 'does not change the value' do
      expect(Setting.get('customer_ticket_create_group_ids')).to eq(setting_value)
    end
  end

  context 'when value is an empty string' do
    let(:setting_value) { '' }

    before do
      Setting.set('customer_ticket_create_group_ids', setting_value)
      migrate
    end

    it 'does change to value to nil' do
      expect(Setting.get('customer_ticket_create_group_ids')).to be_nil
    end
  end

  context 'when value is an empty array string' do
    let(:setting_value) { [''] }

    before do
      Setting.set('customer_ticket_create_group_ids', setting_value)
      migrate
    end

    it 'does change to value to nil' do
      expect(Setting.get('customer_ticket_create_group_ids')).to be_nil
    end
  end
end
