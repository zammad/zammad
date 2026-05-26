# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'zendesk_api'

RSpec.describe Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base do
  let(:zendesk_field_attributes) do
    {
      title:       'Example attribute',
      description: 'Example attribute description',
      removable:   false,
      active:      true,
      position:    12,
      required:    true,
      type:        'text',
    }
  end

  before do
    allow(ObjectManager::Attribute).to receive_messages(add: true, migration_execute: true)
  end

  shared_examples 'imports with default -all- screens config' do |object, zendesk_class|
    let(:attribute) { zendesk_class.new(nil, zendesk_field_attributes) }

    it "sets create/edit/view -all- shown for #{object} fields" do
      described_class.new(object, 'example_field', attribute)

      expect(ObjectManager::Attribute).to have_received(:add).with(
        hash_including(screens: {
                         create: { '-all-' => { shown: true } },
                         edit:   { '-all-' => { shown: true } },
                         view:   { '-all-' => { shown: true } },
                       })
      )
    end
  end

  it_behaves_like 'imports with default -all- screens config', 'User', ZendeskAPI::UserField
  it_behaves_like 'imports with default -all- screens config', 'Organization', ZendeskAPI::OrganizationField
end
