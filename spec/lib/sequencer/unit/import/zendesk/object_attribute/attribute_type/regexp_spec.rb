# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/sequencer/unit/import/zendesk/object_attribute/attribute_type/base_examples'

RSpec.describe Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Regexp do
  let(:regex) { '.+?' }

  it_behaves_like Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base do
    let(:zendesk_object_field_type) { 'regexp' }
    let(:zendesk_object_field_attributes) do
      {
        regexp_for_validation: regex
      }
    end
    let(:object_attribute_type) { 'input' }
    let(:object_attribute_data_option) do
      {
        null:      false,
        note:      'Example attribute description',
        type:      'text',
        maxlength: 255,
        regex:     regex,
      }
    end
  end
end
