# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'models/form_updater/concerns/checks_core_workflow_examples'

RSpec.describe FormUpdater::Updater::User::Notifications do
  subject(:form_updater) do
    described_class.new(
      context:         context,
      meta:            meta,
      data:            data,
      relation_fields: [],
    )
  end

  let(:user)     { create(:user, groups: [group]) }
  let(:group)    { create(:group) }
  let(:context)  { { current_user: user } }
  let(:meta)     { { initial: true, form_id: SecureRandom.uuid } }
  let(:data)     { {} }

  describe '#resolve' do
    it 'return user groups' do
      expect(form_updater.resolve[:fields]).to include(
        'group_ids' => include(
          options: contain_exactly(
            include(
              value: group.id,
            )
          )
        )
      )
    end
  end
end
