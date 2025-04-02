# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormUpdater::Updater::User::Current::NewAccessToken do
  subject(:form_updater) do
    described_class.new(
      context:         context,
      meta:            meta,
      data:            data,
      relation_fields: [],
    )
  end

  let(:user)    { create(:user, roles: [role]) }
  let(:role)    { create(:role, permission_names: %w[admin.user]) }
  let(:context) { { current_user: user } }
  let(:meta)    { { initial: true, form_id: SecureRandom.uuid } }
  let(:data)    { {} }

  let(:permission_admin)      { Permission.find_by! name: 'admin' }
  let(:permission_admin_user) { Permission.find_by! name: 'admin.user' }

  describe '#resolve' do
    it 'returns permissions list for current user' do
      expect(form_updater.resolve[:fields]).to include(
        'permissions' => include(
          options: contain_exactly(
            include(
              value:       'admin',
              label:       permission_admin.label,
              description: permission_admin.description,
              disabled:    be_truthy,
              children:    contain_exactly(
                include(
                  value:       'admin.user',
                  label:       permission_admin_user.label,
                  description: permission_admin_user.description,
                  disabled:    be_falsey,
                )
              )
            )
          )
        )
      )
    end

    it 'uses permission name as fallback if label is not present' do
      permission_admin.update_columns(label: nil)

      expect(form_updater.resolve[:fields]).to include(
        'permissions' => include(
          options: contain_exactly(
            include(
              value: 'admin',
              label: permission_admin.name,
            )
          )
        )
      )
    end
  end
end
