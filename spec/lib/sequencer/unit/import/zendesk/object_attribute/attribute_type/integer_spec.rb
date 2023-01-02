# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/sequencer/unit/import/zendesk/object_attribute/attribute_type/base_examples'

RSpec.describe Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Integer do
  it_behaves_like Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base do
    let(:object_attribute_type) { 'integer' }
    let(:object_attribute_data_option) do
      {
        null: false,
        note: 'Example attribute description',
        min:  0,
        max:  999_999_999,
      }
    end
  end
end
