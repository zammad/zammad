# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormUpdater::Updater::KnowledgeBase::Category::Create) do
  subject(:updater) do
    described_class.new(
      context:         context,
      relation_fields: [],
      meta:            meta,
      data:            data,
    )
  end

  let!(:knowledge_base) { create(:knowledge_base) }
  let(:editor_role)     { create(:role, permission_names: 'knowledge_base.editor') }
  let(:user)            { create(:user, roles: [editor_role]) }
  let(:context)         { { current_user: user } }
  let(:meta)            { { initial: true } }
  let(:data)            { {} }

  def fields
    updater.authorized?
    updater.resolve[:fields]
  end

  describe '#authorized?' do
    it 'authorizes an editor to add a category' do
      expect(updater.authorized?).to be true
    end

    context 'with a reader' do
      let(:user) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }

      it 'is not authorized to add a category' do
        expect(updater.authorized?).to be false
      end
    end

    context 'with a granular editor locked out of everything' do
      # Editor by role permission, but denied on the knowledge base and holding no category
      #   permission — so there is nowhere to create a category.
      before { create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'none') }

      it 'is not authorized to add a category' do
        expect(updater.authorized?).to be false
      end
    end
  end

  describe '#resolve' do
    # An empty parent field already means the top level, and sending an initial value would
    #   overwrite whatever the caller seeded the form with (see Form.vue).
    it 'does not preselect a parent' do
      expect(fields['parentId']).not_to have_key(:initialValue)
    end

    # An empty field is how the form says "top level", so it stays clearable for anyone who may
    #   actually create there.
    it 'leaves the parent optional' do
      expect(fields['parentId']).to include(required: false)
    end

    context 'with a granular editor who may not create at the top level' do
      let!(:permitted_category) { create(:knowledge_base_category, knowledge_base: knowledge_base) }

      before do
        create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'reader')
        create(:knowledge_base_permission, permissionable: permitted_category, role: editor_role, access: 'editor')
      end

      # Clearing the field would mean a move the mutation refuses, so the form has to catch it
      #   before submitting.
      it 'requires a parent' do
        expect(fields['parentId']).to include(required: true)
      end
    end

    it 'defaults the category icon to the knowledge base default' do
      expect(fields['categoryIcon']).to eq(initialValue: knowledge_base.default_category_icon)
    end

    context 'when the form is not being initialized' do
      let(:meta) { { initial: false } }

      it 'does not default the category icon' do
        expect(fields).not_to have_key('categoryIcon')
      end
    end

    describe 'permissions' do
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
        let!(:other_category) { create(:knowledge_base_category, knowledge_base: knowledge_base) }

        # Any permission record anywhere turns granular mode on.
        before { create(:knowledge_base_permission, permissionable: other_category, role: editor_role, access: 'editor') }

        it 'shows the field' do
          expect(fields['permissions']).to include(show: true)
        end

        it 'resolves a row per capable role' do
          expect(rows_by_role_id.keys).to include(editor_role.id, reader_role.id)
        end

        # The rows are the field's `permissionRows` prop; its value is only which access is
        #   picked per role.
        it 'seeds the selection from the resolved rows' do
          expect(fields.dig('permissions', :initialValue))
            .to include(editor_role.id.to_s => 'editor', reader_role.id.to_s => 'reader')
        end

        # The value is a JSON object keyed by role id, and object keys are strings either way —
        #   so the rows have to agree, or the field cannot look a role's selection up.
        it 'identifies the roles by string ids' do
          expect(fields.dig('permissions', :permissionRows)).to all(include(roleId: a_kind_of(String)))
        end

        it 'resolves against the knowledge base when no parent is selected' do
          expect(rows_by_role_id[editor_role.id]).to include(inheritedAccess: nil, allowedAccesses: %w[editor reader none])
        end

        context 'when a parent is selected' do
          let(:data) { { 'parentId' => other_category.id } }

          it 'resolves the inherited access from the selected parent' do
            expect(rows_by_role_id[editor_role.id]).to include(inheritedAccess: 'editor', allowedAccesses: %w[editor])
          end
        end

        # Clearing the field is how the form says "top level", so it has to resolve against the
        #   knowledge base rather than fall through to whatever was picked before.
        context 'when the parent is cleared' do
          let(:data) { { 'parentId' => nil } }

          it 'resolves against the knowledge base' do
            expect(rows_by_role_id[editor_role.id]).to include(inheritedAccess: nil)
          end
        end

        context 'when a parent the user has no access to is submitted' do
          let!(:forbidden_parent) { create(:knowledge_base_category, knowledge_base: knowledge_base) }
          let(:data)              { { 'parentId' => forbidden_parent.id } }

          before do
            create(:knowledge_base_permission, permissionable: forbidden_parent, role: editor_role, access: 'none')
          end

          # Falls back to the knowledge base rather than reporting what the forbidden category
          #   grants, so its permissions cannot be read out through the form.
          it 'ignores the submitted parent' do
            expect(rows_by_role_id[editor_role.id]).to include(inheritedAccess: nil)
          end
        end

        context 'when a parent change makes the selected access illegal' do
          # The shape the form sends its selection back in: role id => access.
          let(:data) do
            {
              'parentId'    => other_category.id,
              'permissions' => { editor_role.id.to_s => 'reader' },
            }
          end

          it 'clamps the access to the only allowed one', :aggregate_failures do
            expect(rows_by_role_id[editor_role.id]).to include(allowedAccesses: %w[editor])
            expect(fields.dig('permissions', :initialValue)).to include(editor_role.id.to_s => 'editor')
          end
        end

        # The whole point of the updater: the selection must not be initial-only, or a parent
        #   change after mount would leave a stale access on the form. It is sent as `value`
        #   there, which is the only thing Form.vue applies to an already mounted field.
        it 'corrects the selection on a non-initial run', :aggregate_failures do
          updater = described_class.new(
            context:         context,
            relation_fields: [],
            meta:            { initial: false },
            data:            { 'parentId' => other_category.id, 'permissions' => { editor_role.id.to_s => 'reader' } },
          )
          updater.authorized?

          field = updater.resolve.dig(:fields, 'permissions')

          expect(field).not_to have_key(:initialValue)
          expect(field[:value]).to include(editor_role.id.to_s => 'editor')
          expect(field[:permissionRows].find { |row| row[:roleId] == editor_role.id.to_s })
            .to include(inheritedAccess: 'editor')
        end
      end
    end
  end

  def rows_by_role_id
    # Keyed back to integers so the examples can use the role objects directly; the wire
    #   shape itself is covered by 'identifies the roles by string ids'.
    fields.dig('permissions', :permissionRows).index_by { |row| row[:roleId].to_i }
  end
end
