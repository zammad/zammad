# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Validations::ObjectManager::AttributeValidator::DataTypes', aggregate_failures: true do

  %w[
    input
    user_autocompletion
    checkbox
    select
    multiselect
    tree_select
    multi_tree_select
    datetime
    date
    tag
    richtext
    textarea
    integer
    autocompletion_ajax
    autocompletion_ajax_customer_organization
    autocompletion_ajax_external_data_source
    boolean
    user_permission
    active
  ].freeze.each do |data_type|
    it "validates #{data_type} data type" do
      expect(ObjectManager::Attribute::DATA_TYPES).to include(data_type)
    end
  end

end
