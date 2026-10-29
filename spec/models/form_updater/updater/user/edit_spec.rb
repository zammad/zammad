# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'models/form_updater/concerns/checks_core_workflow_examples'

RSpec.describe(FormUpdater::Updater::User::Edit) do
  subject(:resolved_result) do
    described_class.new(
      context:         context,
      relation_fields: relation_fields,
      meta:            meta,
      data:            data,
      id:              Gql::ZammadSchema.id_from_object(edit_user)
    )
  end

  let(:user)                    { create(:agent) }
  let(:context)                 { { current_user: user } }
  let(:meta)                    { { initial: true, form_id: SecureRandom.uuid } }
  let(:data)                    { {} }
  let(:organization)            { create(:organization) }
  let(:secondary_organizations) { create_list(:organization, 5) }
  let(:edit_user)               { create(:user, organization_id: organization.id, organization_ids: secondary_organizations.map(&:id)) }
  let(:relation_fields)         { [] }

  context 'when resolving' do
    it 'has permission on the object' do
      expect(resolved_result.authorized?).to be true
    end

    it 'returns secondary organization options for current object in initial request' do
      # Triggers the object initialization from the id.
      resolved_result.authorized?

      expect(resolved_result.resolve[:fields]).to include(
        'organization_ids' => include({
                                        initialValue: secondary_organizations.map(&:id),
                                        options:      secondary_organizations.each_with_object([]) do |organization, options|
                                                        options << {
                                                          value:        organization.id,
                                                          label:        organization.name,
                                                          organization: {
                                                            active: organization.active,
                                                          }
                                                        }
                                                      end
                                      }),
      )
    end
  end

  describe '#authorized?' do
    context 'with a customer opening the form for their own account' do
      let(:user)      { create(:customer) }
      let(:edit_user) { user }

      it 'is not authorized' do
        expect(resolved_result.authorized?).to be false
      end
    end

    context 'with an agent opening the form for a user they may not change' do
      let(:edit_user) { create(:agent) }

      it 'is not authorized' do
        expect { resolved_result.authorized? }.to raise_error(Exceptions::Forbidden)
      end
    end
  end

  include_examples 'FormUpdater::ChecksCoreWorkflow', object_name: 'User'
end
