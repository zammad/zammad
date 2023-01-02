# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'models/form_updater/concerns/checks_core_workflow_examples'

RSpec.describe(FormUpdater::Updater::Organization::Edit) do
  subject(:resolved_result) do
    described_class.new(
      context:         context,
      relation_fields: relation_fields,
      meta:            meta,
      data:            data,
      id:              nil
    )
  end

  let(:user)    { create(:agent) }
  let(:context) { { current_user: user } }
  let(:meta)    { { initial: true, form_id: 12_345 } }
  let(:data)    { {} }
  let(:relation_fields) do
    []
  end

  include_examples 'ChecksCoreWorkflow', object_name: 'Organization'
end
