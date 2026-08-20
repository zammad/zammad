# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::RolePermissions do
  subject(:service) { described_class.new(parent: parent, current_permissions: current_permissions) }

  let(:knowledge_base)      { create(:knowledge_base) }
  let(:parent)              { knowledge_base }
  let(:current_permissions) { {} }

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:reader_role) { create(:role, permission_names: 'knowledge_base.reader') }

  def row_for(role)
    service.execute.find { |row| row[:roleId] == role.id }
  end

  describe '#execute' do
    it 'returns a row per capable role' do
      expect(row_for(editor_role)).to include(roleId: editor_role.id, roleName: editor_role.name)
    end

    it 'omits roles that cannot hold any knowledge base access' do
      unrelated_role = create(:role, permission_names: 'ticket.agent')

      expect(row_for(unrelated_role)).to be_nil
    end

    describe 'allowedAccesses' do
      # The disable matrix ported from the coffee permissions dialog: what a role may be set to,
      #   given its own global permission and what it inherits from the parent.
      shared_examples 'an access matrix cell' do |inherited:, expected:|
        it "allows #{expected.inspect}" do
          expect(row_for(role)).to include(allowedAccesses: expected, inheritedAccess: inherited)
        end
      end

      # Inherited access comes from an explicit permission on the parent object.
      def inherit!(role, access)
        create(:knowledge_base_permission, permissionable: parent, role: role, access: access)
      end

      context 'with an editor-capable role' do
        let(:role) { editor_role }

        context 'when nothing is inherited' do
          it_behaves_like 'an access matrix cell', inherited: nil, expected: %w[editor reader none]
        end

        context "when 'reader' is inherited" do
          before { inherit!(role, 'reader') }

          it_behaves_like 'an access matrix cell', inherited: 'reader', expected: %w[editor reader none]
        end

        context "when 'editor' is inherited" do
          before { inherit!(role, 'editor') }

          it_behaves_like 'an access matrix cell', inherited: 'editor', expected: %w[editor]
        end

        context "when 'none' is inherited" do
          before { inherit!(role, 'none') }

          it_behaves_like 'an access matrix cell', inherited: 'none', expected: %w[none]
        end
      end

      # No inherited-'editor' cell here: KnowledgeBase::Permission#ensure_access_matches_role
      #   rejects an 'editor' permission for a role that is not editor-capable, so a reader-only
      #   role can never inherit it.
      context 'with a reader-only role' do
        let(:role) { reader_role }

        context 'when nothing is inherited' do
          it_behaves_like 'an access matrix cell', inherited: nil, expected: %w[reader none]
        end

        context "when 'reader' is inherited" do
          before { inherit!(role, 'reader') }

          it_behaves_like 'an access matrix cell', inherited: 'reader', expected: %w[reader none]
        end

        context "when 'none' is inherited" do
          before { inherit!(role, 'none') }

          it_behaves_like 'an access matrix cell', inherited: 'none', expected: %w[none]
        end
      end
    end

    describe 'access' do
      it 'falls back to the inherited access when nothing is selected' do
        create(:knowledge_base_permission, permissionable: parent, role: editor_role, access: 'reader')

        expect(row_for(editor_role)).to include(access: 'reader', inheritedAccess: 'reader')
      end

      # Without any permission record a role already has the access its own permission grants
      #   (KnowledgeBase::EffectivePermission#default_role_access), so that is what the form must
      #   show. Defaulting to 'none' would misreport it and, once saved, lock the user out.
      it 'falls back to the access the role holds by its own permission' do
        expect(row_for(editor_role)).to include(access: 'editor', inheritedAccess: nil)
      end

      it 'falls back to reader for a role that cannot be an editor' do
        expect(row_for(reader_role)).to include(access: 'reader', inheritedAccess: nil)
      end

      context 'with a selected access' do
        let(:current_permissions) { { editor_role.id => 'editor' } }

        it 'keeps a selection that is still allowed' do
          expect(row_for(editor_role)).to include(access: 'editor')
        end

        it 'accepts string keys, as sent back by the form' do
          service = described_class.new(parent: parent, current_permissions: { editor_role.id.to_s => 'editor' })

          expect(service.execute.find { |row| row[:roleId] == editor_role.id }).to include(access: 'editor')
        end
      end

      context 'when the parent narrows the allowed accesses' do
        let(:current_permissions) { { editor_role.id => 'editor' } }

        before { create(:knowledge_base_permission, permissionable: parent, role: editor_role, access: 'none') }

        it 'clamps a selection that is no longer allowed' do
          expect(row_for(editor_role)).to include(access: 'none', allowedAccesses: %w[none])
        end
      end
    end

    context 'with a category as parent' do
      let(:category) { create(:knowledge_base_category, knowledge_base: knowledge_base) }
      let(:parent)   { category }

      it 'inherits from the category, not the knowledge base' do
        create(:knowledge_base_permission, permissionable: category, role: editor_role, access: 'reader')

        expect(row_for(editor_role)).to include(inheritedAccess: 'reader')
      end

      it 'inherits the knowledge base access through the category' do
        create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'none')

        expect(row_for(editor_role)).to include(inheritedAccess: 'none')
      end
    end

    context 'without a parent' do
      let(:parent) { nil }

      it 'does not treat the knowledge base stored permissions as inherited' do
        create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'editor')

        expect(row_for(editor_role)).to include(inheritedAccess: nil, allowedAccesses: %w[editor reader none])
      end
    end
  end
end
