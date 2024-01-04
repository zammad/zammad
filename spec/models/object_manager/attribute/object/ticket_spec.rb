# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'ObjectManager::Attribute::Object::Ticket', aggregate_failures: true, db_strategy: :reset do
  shared_context 'with ticket attribute setup' do
    before { attribute }

    let(:attribute) do
      attribute = create(:object_manager_attribute_text)
      ObjectManager::Attribute.migration_execute

      attribute
    end
    let(:ticket) { create(:ticket) }
  end

  describe 'add ticket attribute' do
    include_context 'with ticket attribute setup'

    it 'is successful' do
      ticket.update(attribute.name => 'Bazinga!')
      expect(ticket.reload).to have_attributes(attribute.name => 'Bazinga!')
    end
  end

  describe 'update ticket attribute' do
    include_context 'with ticket attribute setup'

    it 'is successful' do
      skip 'Missing error handling on edit misconfiguration.'

      ticket.update!(attribute.name => 'Bazinga!')

      attributes = attribute.attributes
      attributes.delete('data_option_new')
      attributes['data_option'] = {
        maxlength: 3,
        type:      'text',
        null:      false,
      }
      ObjectManager::Attribute.add(attributes.deep_symbolize_keys)
      ObjectManager::Attribute.migration_execute
      expect { ticket.reload }.not_to raise_error

      new_ticket = create(:ticket).tap { |t| t.update!(attribute.name => 'Bazinga!') }
      expect(new_ticket.attributes[attribute.name].length).to be(3)
    end
  end

  describe 'remove ticket attribute' do
    include_context 'with ticket attribute setup'

    it 'is successful' do
      ticket.update!(attribute.name => 'Bazinga!')

      attribute_name = attribute.name
      ObjectManager::Attribute.remove(
        object: 'Ticket',
        name:   attribute_name
      )
      ObjectManager::Attribute.migration_execute
      expect(ticket.reload.attributes).not_to include(attribute_name)
    end
  end
end
