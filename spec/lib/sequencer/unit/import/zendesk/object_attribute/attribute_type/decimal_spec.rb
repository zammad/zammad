# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/sequencer/unit/import/zendesk/object_attribute/attribute_type/base_examples'

RSpec.describe Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Decimal do
  it_behaves_like Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base do
    let(:zendesk_object_field_type) { 'decimal' }
  end
end
