# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormUpdater::Relation::KnowledgeBaseEditorCategory do
  subject(:relation) do
    described_class.new(
      context:           {},
      current_user:      current_user,
      knowledge_base:    knowledge_base,
      excluded_category: excluded_category,
      kb_locale:         kb_locale,
    )
  end

  let(:knowledge_base)    { create(:knowledge_base) }
  let(:kb_locale)         { knowledge_base.kb_locales.first }
  let(:excluded_category) { nil }
  let(:current_user)      { create(:user, roles: [create(:role, permission_names: 'knowledge_base.editor')]) }

  def title_of(category)
    category.translation_preferred(kb_locale).title
  end

  describe '#options' do
    # The top level is an empty selection in the form, not an entry of its own.
    it 'offers nothing for a knowledge base without categories' do
      expect(relation.options).to be_empty
    end

    context 'with a category tree' do
      let!(:root)       { create(:knowledge_base_category, knowledge_base: knowledge_base) }
      let!(:child)      { create(:knowledge_base_category, knowledge_base: knowledge_base, parent: root) }
      let!(:grandchild) { create(:knowledge_base_category, knowledge_base: knowledge_base, parent: child) }

      it 'nests the categories along the tree' do
        expect(relation.options).to eq(
          [
            {
              value:    root.id,
              label:    title_of(root),
              children: [
                {
                  value:    child.id,
                  label:    title_of(child),
                  children: [{ value: grandchild.id, label: title_of(grandchild) }],
                },
              ],
            },
          ]
        )
      end

      it 'omits the children key on a leaf' do
        expect(relation.options.last.dig(:children, 0, :children, 0)).not_to have_key(:children)
      end

      context 'when editing a category' do
        let(:excluded_category) { child }

        it 'omits the edited category and its whole subtree' do
          expect(option_values).to contain_exactly(root.id)
        end
      end

    end

    context 'with a user without editor permission' do
      let(:current_user) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }

      before { create(:knowledge_base_category, knowledge_base: knowledge_base) }

      it 'offers nothing', :aggregate_failures do
        expect(relation.options).to be_empty
        expect(relation).not_to be_top_level_selectable
      end
    end

    context 'with a granular editor' do
      let!(:root)          { create(:knowledge_base_category, knowledge_base: knowledge_base) }
      let!(:permitted)     { create(:knowledge_base_category, knowledge_base: knowledge_base, parent: root) }
      let!(:not_permitted) { create(:knowledge_base_category, knowledge_base: knowledge_base) }

      let(:granular_role) { create(:role, permission_names: 'knowledge_base.editor') }
      let(:current_user)  { create(:user, roles: [granular_role]) }

      # Reader on the knowledge base plus editor on one subcategory — the constructible granular
      #   setup: PermissionsUpdate only lets a child override a 'reader' parent.
      before do
        create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader')
        create(:knowledge_base_permission, permissionable: permitted, role: granular_role, access: 'editor')
      end

      it 'only offers the categories the user may create under' do
        expect(option_values).to include(permitted.id).and(not_include(root.id, not_permitted.id))
      end

      it 'offers a permitted category whose parent is not permitted as a top level tree' do
        expect(relation.options.pluck(:value)).to include(permitted.id)
      end

      # A top level category is created under the knowledge base, which CategoryPolicy#create?
      #   only allows for an editor of the knowledge base itself — so clearing the parent field
      #   is not a legal choice for this user, and the updater has to reject it.
      it 'reports the top level as unselectable for a user who may not create in the knowledge base' do
        expect(relation).not_to be_top_level_selectable
      end
    end

    context 'with another knowledge base' do
      let!(:other_category) { create(:knowledge_base_category) }

      it 'only offers categories of the given knowledge base' do
        expect(option_values).not_to include(other_category.id)
      end
    end
  end

  describe '#options_key', :aggregate_failures do
    let!(:root)  { create(:knowledge_base_category, knowledge_base: knowledge_base) }
    let!(:child) { create(:knowledge_base_category, knowledge_base: knowledge_base, parent: root) }

    # A relation of its own each time, as one request has: it reads the categories once.
    def options_key(excluded_category: nil, kb_locale: self.kb_locale)
      described_class.new(context: {}, current_user:, knowledge_base: KnowledgeBase.find(knowledge_base.id), excluded_category:, kb_locale:).options_key
    end

    it 'changes with the categories offered and the locale their titles read in' do
      key = options_key

      expect(options_key).to eq(key)
      expect(options_key(excluded_category: child)).not_to eq(key)

      other_locale = create(:knowledge_base_locale, knowledge_base: knowledge_base, system_locale: Locale.find_by(locale: 'de-de'))
      added        = options_key

      expect(added).not_to eq(key)
      expect(options_key(kb_locale: other_locale)).not_to eq(added)

      # A category without a title in the locale asked for reads in the primary one.
      knowledge_base.kb_locales.find_by(primary: true).update!(primary: false)
      other_locale.update!(primary: true)

      expect(options_key).not_to eq(added)
    end

    it 'changes with a title also where the categories offered come from a kept list' do
      role = current_user.roles.first
      create(:knowledge_base_permission, permissionable: knowledge_base, role:, access: 'reader')
      create(:knowledge_base_permission, permissionable: child, role:, access: 'editor')

      # The kept list is found by the latest change of all categories, which a change before it does not move.
      root.update_columns(updated_at: 5.seconds.from_now)
      key = options_key

      child.translations.first.update!(title: 'Renamed')

      expect(options_key).not_to eq(key)
    end

    it 'changes with a title, a move and a new position of a category' do
      keys = [
        -> {},
        -> { child.translations.first.update!(title: 'Renamed') },
        -> { child.update!(parent: nil) },
        -> { child.update!(position: 99) },
      ].map do |change|
        travel 1.second
        change.call

        options_key
      end

      expect(keys.uniq.size).to eq(4)
    end
  end

  # Flattened values of the whole option tree.
  def option_values
    flatten = lambda do |options|
      options.flat_map { |option| [option[:value]] + flatten.call(option[:children] || []) }
    end

    flatten.call(relation.options)
  end

  matcher :not_include do |*expected|
    match { |actual| expected.none? { |value| actual.include?(value) } }
  end
end
