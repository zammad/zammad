# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    context 'when a granted permission has no priority' do
      let(:role) { create(:role, permission_names: %w[admin.user custom_permission]) }

      before { create(:permission, name: 'custom_permission', label: 'Custom', preferences: {}) }

      it 'sorts it after the prioritized permissions' do
        expect(form_updater.resolve[:fields]['permissions'][:options].pluck(:value))
          .to eq(%w[admin custom_permission])
      end
    end

    context 'when the parent of a granted permission is inactive' do
      let(:role)            { create(:role, permission_names: %w[admin.user chat.agent]) }
      let(:permission_chat) { Permission.find_by! name: 'chat' }

      before { permission_chat.update!(active: false) }

      it 'lists the permission below its disabled parent' do
        expect(form_updater.resolve[:fields]['permissions'][:options]).to include(
          include(
            value:       'chat',
            label:       permission_chat.label,
            description: permission_chat.description,
            disabled:    true,
            children:    contain_exactly(
              include(
                value:    'chat.agent',
                disabled: be_falsey,
              )
            )
          )
        )
      end
    end

    context 'when the parent of a granted permission does not exist' do
      let(:role) { create(:role, permission_names: %w[admin.user custom.child]) }

      before { create(:permission, name: 'custom.child', label: 'Custom child', preferences: {}) }

      it 'lists the permission below a disabled placeholder named after the parent' do
        expect(form_updater.resolve[:fields]['permissions'][:options]).to include(
          include(
            value:    'custom',
            label:    'custom',
            disabled: true,
            children: contain_exactly(
              include(
                value:    'custom.child',
                disabled: be_falsey,
              )
            )
          )
        )
      end
    end
  end
end
