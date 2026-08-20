# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormUpdater::Updater::KnowledgeBase::Edit) do
  subject(:updater) do
    described_class.new(
      context:         context,
      relation_fields: [],
      meta:            meta,
      data:            data,
      id:              id,
    )
  end

  let!(:knowledge_base) { create(:knowledge_base) }
  let(:editor_role)     { create(:role, permission_names: 'knowledge_base.editor') }
  let(:user)            { create(:user, roles: [editor_role]) }
  let(:context)         { { current_user: user } }
  let(:meta)            { { initial: true } }
  let(:data)            { {} }
  let(:id)              { Gql::ZammadSchema.id_from_object(knowledge_base) }

  def fields
    updater.authorized?
    updater.resolve[:fields]
  end

  describe '#authorized?' do
    it 'authorizes an editor and loads the knowledge base', :aggregate_failures do
      expect(updater.authorized?).to be true
      expect(updater.object).to eq(knowledge_base)
    end

    context 'without an id' do
      let(:id) { nil }

      it 'is not authorized' do
        expect(updater.authorized?).to be false
      end
    end

    context 'with a reader' do
      let(:user) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }

      it 'is not authorized' do
        expect(updater.authorized?).to be false
      end
    end

    context 'with a granular reader of the knowledge base root' do
      before { create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'reader') }

      it 'is not authorized' do
        expect { updater.authorized? }.to raise_error(Exceptions::Forbidden)
      end
    end
  end

  describe '#resolve' do
    let!(:reader_role) { create(:role, permission_names: 'knowledge_base.reader') }

    # Granular permissions begin with the first one granted here, so the matrix cannot wait for
    #   them to exist. Saving it untouched stores nothing (see AppliesPermissions).
    context 'without granular permissions' do
      it 'offers the field seeded with what the roles have anyway', :aggregate_failures do
        expect(KnowledgeBase).not_to be_granular_permissions
        expect(fields['permissions']).to include(show: true)
        expect(fields.dig('permissions', :initialValue))
          .to include(editor_role.id.to_s => 'editor', reader_role.id.to_s => 'reader')
      end
    end

    context 'with granular permissions' do
      # The editing user's own role must keep editor access on the root, or the form is forbidden
      #   before it resolves anything (see #authorized? above). The second role is what makes the
      #   stored permissions more than the user's own row.
      before do
        create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'editor')
        create(:knowledge_base_permission, permissionable: knowledge_base, role: reader_role, access: 'reader')
      end

      it 'shows the permissions field' do
        expect(fields['permissions']).to include(show: true)
      end

      it 'seeds the selection from the root permissions' do
        expect(fields.dig('permissions', :initialValue))
          .to include(editor_role.id.to_s => 'editor', reader_role.id.to_s => 'reader')
      end

      it 'resolves root rows without inherited access', :aggregate_failures do
        row = rows_by_role_id[editor_role.id]

        expect(row).to include(roleId: editor_role.id.to_s, inheritedAccess: nil)
        expect(row[:allowedAccesses]).to eq(%w[editor reader none])

        # A role is still capped by its own global permission.
        expect(rows_by_role_id[reader_role.id][:allowedAccesses]).to eq(%w[reader none])
      end

      it 'identifies the roles by string ids' do
        expect(fields.dig('permissions', :permissionRows)).to all(include(roleId: a_kind_of(String)))
      end

      it 'corrects the selection on a non-initial run', :aggregate_failures do
        updater = described_class.new(
          context:         context,
          relation_fields: [],
          meta:            { initial: false },
          data:            { 'permissions' => { editor_role.id.to_s => 'editor' } },
          id:              id,
        )
        updater.authorized?

        field = updater.resolve.dig(:fields, 'permissions')

        expect(field).not_to have_key(:initialValue)
        expect(field[:value]).to include(editor_role.id.to_s => 'editor')
      end
    end
  end

  def rows_by_role_id
    fields.dig('permissions', :permissionRows).index_by { |row| row[:roleId].to_i }
  end
end
