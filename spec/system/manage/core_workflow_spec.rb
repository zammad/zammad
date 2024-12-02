# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > CoreWorkflow', type: :system do
  context 'when ajax pagination' do
    include_examples 'pagination', model: :core_workflow, klass: CoreWorkflow, path: 'manage/core_workflow', create_params: { changeable: true }, sort_by: :priority
  end
end
