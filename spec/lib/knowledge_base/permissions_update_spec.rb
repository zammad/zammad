# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe KnowledgeBase::PermissionsUpdate do
  describe '#update!' do
    include_context 'basic Knowledge Base'

    let(:role_editor)    { create(:role, permission_names: %w[knowledge_base.editor]) }
    let(:role_another)   { create(:role, permission_names: %w[knowledge_base.editor]) }
    let(:role_reader)    { create(:role, permission_names: %w[knowledge_base.reader]) }
    let(:child_category) { create(:knowledge_base_category, parent: category) }

    describe 'updating itself' do
      shared_examples 'updating itself' do |object_name:|
        let(:object) { send(object_name) }
        it 'adds role permission for self' do
          described_class.new(object).update! role_editor => 'editor'

          expect(object.permissions)
            .to contain_exactly have_attributes(permissionable: object, role: role_editor, access: 'editor')
        end

        it 'adds additional role permission for self' do
          described_class.new(object).update! role_editor => 'reader'
          described_class.new(object).update! role_editor => 'reader', role_another => 'reader'

          expect(object.permissions)
            .to contain_exactly(have_attributes(role: role_editor), have_attributes(role: role_another))
        end

        it 'does not update when re-adding an existing permission' do
          described_class.new(object).update! role_editor => 'reader'

          expect { described_class.new(object).update! role_editor => 'reader' }
            .not_to change(object, :updated_at)
        end

        it 'throws error when role does not allow given access' do
          expect { described_class.new(object).update! role_reader => 'editor' }
            .to raise_error(%r{Validation failed})
        end
      end

      context 'when saving role on KB itself' do
        include_context 'updating itself', object_name: :knowledge_base
      end

      context 'when saving role on KB category' do
        include_context 'updating itself', object_name: :category
      end
    end

    describe 'updating descendants' do
      context 'when saving role on KB itself' do
        it 'adds effective permissions to descendant categories' do
          described_class.new(knowledge_base).update! role_editor => 'reader'

          expect(category.permissions_effective)
            .to contain_exactly have_attributes(role: role_editor, access: 'reader', permissionable: knowledge_base)
        end

        it 'removing permission opens up access to descendants' do
          described_class.new(knowledge_base).update! role_editor => 'editor'
          described_class.new(knowledge_base).update!(**{})

          expect(category.permissions_effective).to be_blank
        end

        context 'when category has editor role has editor role with editor permission' do
          before do
            described_class.new(category).update! role_editor => 'editor'
            category.reload
          end

          it 'removes identical permissions on descendant roles' do
            described_class.new(knowledge_base).update! role_editor => 'editor'
            category.reload

            expect(category.permissions_effective)
              .to contain_exactly have_attributes(role: role_editor, access: 'editor', permissionable: knowledge_base)
          end
        end
      end

      context 'when saving role on KB category' do
        it 'adds effective permissions to descendant roles' do
          described_class.new(category).update! role_editor => 'reader'

          expect(child_category.permissions_effective)
            .to contain_exactly have_attributes(role: role_editor, access: 'reader', permissionable: category)
        end

        context 'when child category has editor role with editor permission' do
          before do
            described_class.new(child_category).update! role_editor => 'editor'
            category.reload
            child_category.reload
          end

          it 'removes conflicting permissions on descendant roles' do
            described_class.new(category).update! role_editor => 'none'
            category.reload
            child_category.reload

            expect(child_category.permissions_effective)
              .to contain_exactly have_attributes(role: role_editor, access: 'none', permissionable: category)
          end

          it 'removes identical permissions on descendant roles' do
            described_class.new(category).update! role_editor => 'editor'
            category.reload
            child_category.reload

            expect(child_category.permissions_effective)
              .to contain_exactly have_attributes(role: role_editor, access: 'editor', permissionable: category)
          end
        end

        context 'when category has role editor with none permission' do
          before do
            described_class.new(category).update! role_editor => 'none'
            category.reload
          end

          it 'removing permission opens up access to descendants' do
            described_class.new(category).update!(**{})
            category.reload

            expect(child_category.permissions_effective).to be_blank
          end
        end
      end
    end

    describe 'preventing user lockout' do
      let(:user) { create(:admin) }
      let(:role) { user.roles.first }

      shared_examples 'preventing user lockout' do |object_name:|
        let(:object) { send(object_name) }

        it 'raises an error when saving a lockout change for a given user' do
          expect { described_class.new(object, user).update! role => 'reader' }
            .to raise_error(Exceptions::UnprocessableEntity)
        end

        it 'allows to save same change without a user' do
          expect { described_class.new(object).update! role => 'reader' }.not_to raise_error
        end
      end

      context 'when saving role on KB itself' do
        include_context 'preventing user lockout', object_name: 'knowledge_base'
      end

      context 'when saving role on KB category' do
        include_context 'preventing user lockout', object_name: 'category'
      end
    end
  end

  describe '#update_using_params!' do
    subject(:updater) { described_class.new(category) }

    let(:role)     { create(:role, permission_names: %w[knowledge_base.editor]) }
    let(:category) { create(:knowledge_base_category) }

    it 'calls update! with given roles' do
      updater.update_using_params!({ permissions: { role.id => 'editor' } })
      expect(category.permissions.first).to have_attributes(role: role, access: 'editor', permissionable: category)
    end

    it 'raises an error when given a non existant role' do
      expect { updater.update_using_params!({ permissions: { (role.id + 1) => 'editor' } }) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
