# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormUpdater::Updater::KnowledgeBase::Category::Edit) do
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
  let(:kb_locale)       { knowledge_base.kb_locales.first }
  let(:editor_role)     { create(:role, permission_names: 'knowledge_base.editor') }
  let(:user)            { create(:user, roles: [editor_role]) }
  let(:context)         { { current_user: user } }
  let(:meta)            { { initial: true } }
  let(:data)            { {} }
  let(:category)        { create(:knowledge_base_category, knowledge_base: knowledge_base) }
  let(:id)              { Gql::ZammadSchema.id_from_object(category) }

  def fields
    updater.authorized?
    updater.resolve[:fields]
  end

  describe '#authorized?' do
    it 'authorizes an editor and loads the category', :aggregate_failures do
      expect(updater.authorized?).to be true
      expect(updater.object).to eq(category)
    end

    context 'without an id' do
      let(:id) { nil }

      it 'is not authorized' do
        expect(updater.authorized?).to be false
      end
    end

    context 'with a reader' do
      let(:user) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }

      # Rejected by the permission gate before the category is even loaded.
      it 'is not authorized' do
        expect(updater.authorized?).to be false
      end
    end

    context 'with a granular reader of the edited category' do
      # Globally an editor, but narrowed to reader on this category — CategoryPolicy#show? would
      #   let this through, #update? must not.
      before { create(:knowledge_base_permission, permissionable: category, role: editor_role, access: 'reader') }

      it 'is not authorized' do
        expect { updater.authorized? }.to raise_error(Exceptions::Forbidden)
      end
    end
  end

  describe '#resolve' do
    let!(:parent)   { create(:knowledge_base_category, knowledge_base: knowledge_base) }
    let(:category)  { create(:knowledge_base_category, knowledge_base: knowledge_base, parent: parent) }
    let!(:child)    { create(:knowledge_base_category, knowledge_base: knowledge_base, parent: category) }

    it 'uses the stored parent as the initial value' do
      expect(fields['parentId']).to include(initialValue: parent.id)
    end

    # An empty field is how the form shows the top level, so a top level category must not be
    #   given an initial value at all.
    context 'with a top level category' do
      let(:category) { create(:knowledge_base_category, knowledge_base: knowledge_base) }

      it 'leaves the parent unset' do
        expect(fields['parentId']).not_to have_key(:initialValue)
      end
    end

    it 'leaves the parent optional' do
      expect(fields['parentId']).to include(required: false)
    end

    context 'with a granular editor who may not move to the top level' do
      before do
        create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'reader')
        create(:knowledge_base_permission, permissionable: parent, role: editor_role, access: 'editor')
      end

      # Clearing the field would mean a move the mutation refuses, so the form has to catch it
      #   before submitting.
      it 'requires a parent' do
        expect(fields['parentId']).to include(required: true)
      end
    end

    it 'does not default the category icon, the category has its own' do
      expect(fields).not_to have_key('categoryIcon')
    end

    it 'omits the edited category and its subtree from the parent options' do
      expect(option_values(fields['parentId'][:options]))
        .to include(parent.id)
        .and(not_include(category.id, child.id))
    end

    # The stored parent is the initial value only; resending it on a later run would overwrite
    #   the selection the user has made since.
    it 'does not resend the stored parent after the initial run' do
      updater = described_class.new(context: context, relation_fields: [], meta: { initial: false }, data: {}, id: id)
      updater.authorized?

      expect(updater.resolve.dig(:fields, 'parentId')).not_to have_key(:initialValue)
    end

    context 'when the category belongs to another knowledge base' do
      let(:other_knowledge_base) { create(:knowledge_base) }
      let!(:other_parent)        { create(:knowledge_base_category, knowledge_base: other_knowledge_base) }
      let(:category)             { create(:knowledge_base_category, knowledge_base: other_knowledge_base, parent: other_parent) }

      # The edited category stays in its own knowledge base, so the options must come from there
      #   and not from whichever knowledge base happens to be first.
      it 'offers the parents of the category own knowledge base' do
        expect(option_values(fields['parentId'][:options])).to include(other_parent.id)
      end
    end

    describe 'permissions' do
      let!(:reader_role) { create(:role, permission_names: 'knowledge_base.reader') }

      context 'when editing a category with its own permissions' do
        before { create(:knowledge_base_permission, permissionable: category, role: reader_role, access: 'reader') }

        # The stored access is the selection, which lives in the field's value rather than in
        #   its rows.
        it 'seeds the selection from the stored permission' do
          expect(fields.dig('permissions', :initialValue)).to include(reader_role.id.to_s => 'reader')
        end
      end

      context 'when the parent is cleared by a user who may not move to the top level' do
        let(:data) { { 'parentId' => nil } }

        before do
          create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'reader')
          create(:knowledge_base_permission, permissionable: parent, role: editor_role, access: 'editor')
        end

        # Such a move could not be saved, so the preview stays with the stored parent (editor
        #   here) instead of resolving against the knowledge base (reader here).
        it 'previews against the stored parent instead' do
          expect(rows_by_role_id[editor_role.id]).to include(inheritedAccess: 'editor')
        end
      end
    end
  end

  def rows_by_role_id
    # Keyed back to integers so the examples can use the role objects directly; the wire
    #   shape itself is covered by 'identifies the roles by string ids'.
    fields.dig('permissions', :permissionRows).index_by { |row| row[:roleId].to_i }
  end

  def option_values(options)
    options.flat_map { |option| [option[:value]] + option_values(option[:children] || []) }
  end

  matcher :not_include do |*expected|
    match { |actual| expected.none? { |value| actual.include?(value) } }
  end
end
