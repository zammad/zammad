# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/sequencer/unit/import/zendesk/object_attribute/attribute_type/base_examples'

RSpec.describe Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Checkbox do
  it_behaves_like Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base do
    let(:zendesk_object_field_type) { 'checkbox' }
    let(:object_attribute_type)     { 'boolean' }
    let(:object_attribute_data_option) do
      {
        null:    false,
        note:    'Example attribute description',
        default: false,
        options: {
          true  => 'yes',
          false => 'no'
        }
      }
    end
  end
end
