# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
  let(:meta)    { { initial: true, form_id: SecureRandom.uuid } }
  let(:data)    { {} }
  let(:relation_fields) do
    []
  end

  describe '#authorized?' do
    it 'is authorized for agents' do
      expect(resolved_result.authorized?).to be true
    end

    context 'with a customer opening the form for their own organization' do
      subject(:resolved_result) do
        described_class.new(context:, relation_fields:, meta:, data:, id: Gql::ZammadSchema.id_from_object(organization))
      end

      let(:organization) { create(:organization) }
      let(:user)         { create(:customer, organization:) }

      it 'is not authorized' do
        expect(resolved_result.authorized?).to be false
      end
    end
  end

  include_examples 'FormUpdater::ChecksCoreWorkflow', object_name: 'Organization'
end
