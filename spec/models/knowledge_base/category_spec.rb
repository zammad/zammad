# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/checks_kb_client_notification_examples'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Category, type: :model, current_user_id: 1 do
  subject(:kb_category) { create(:knowledge_base_category) }

  include_context 'factory'

  it_behaves_like 'ChecksKbClientNotification'

  it { is_expected.to validate_presence_of(:category_icon) }
  it { is_expected.not_to validate_presence_of(:parent_id) }

  it { is_expected.to have_many(:answers) }
  it { is_expected.to have_many(:children) }
  it { is_expected.to belong_to(:parent).optional }
  it { is_expected.to belong_to(:knowledge_base) }

  context 'in multilevel tree' do
    subject(:kb_category_with_tree) { create(:kb_category_with_tree) }

    let(:knowledge_base) { kb_category_with_tree.knowledge_base }
    let(:child_category) { kb_category_with_tree.children.order(position: :asc).last }
    let(:grandchild_category) { child_category.children.order(position: :asc).first }

    it 'tests to fetch all categories in KB' do
      expect(knowledge_base.categories.count).to eq(7)
    end

    it 'fetches root categories' do
      expect(knowledge_base.categories.root).to contain_exactly(kb_category_with_tree)
    end

    it 'fetches direct children' do
      expect(kb_category_with_tree.children.count).to eq 2
    end

    it 'fetches all children' do
      expect(kb_category_with_tree.self_with_children.count).to eq 7
    end

    it 'fetches all parents' do
      expect(grandchild_category.self_with_parents.count).to eq 3
    end

    it 'root category has no parent' do
      expect(kb_category_with_tree.parent).to be_blank
    end

    it 'children category has to have a parent' do
      expect(child_category.parent).to be_present
    end

    context 'when fetching self with children' do
      it 'root category has multiple layers children and matches all KB categories' do
        expect(kb_category_with_tree.self_with_children).to match_array(knowledge_base.categories)
      end

      it 'child category has multiple layers of children' do
        expect(child_category.self_with_children.count).to eq 5
      end

      it 'grandchild category has single layer of children' do
        expect(grandchild_category.self_with_children.count).to eq 3
      end
    end

    context 'when fetchching self with children ids' do
      it 'root category has multiple layers children ids' do
        expect(kb_category_with_tree.self_with_children_ids).to match_array(knowledge_base.category_ids)
      end

      it 'child category has with multiple layers of children ids' do
        expect(child_category.self_with_children_ids.count).to eq 5
      end

      it 'grandchild category has single layer of children ids count' do
        expect(grandchild_category.self_with_children_ids.count).to eq 3
      end

      it 'grandchild category children ids matches direct children ids' do
        expect(grandchild_category.self_with_children_ids).to match_array([grandchild_category.id] + grandchild_category.child_ids)
      end
    end

    context 'when checking if item is a parent of' do
      it 'root category is indirect (and direct) parent of child' do
        expect(child_category).to be_self_parent(kb_category_with_tree)
      end

      it 'root category is indirect parent of grandchild' do
        expect(grandchild_category).to be_self_parent(kb_category_with_tree)
      end

      it 'child category is not a parent of root category' do
        expect(kb_category_with_tree).not_to be_self_parent(grandchild_category)
      end
    end
  end

  describe '#public_content?' do
    shared_examples 'verify visibility in given state' do |state:, is_visible:|
      it "returns #{is_visible} when contains #{state} answer" do
        object = create(:knowledge_base_category, "containing_#{state}")

        expect(object).send is_visible ? :to : :not_to, be_public_content(object.translations.first.kb_locale)
      end
    end

    include_examples 'verify visibility in given state', state: :published, is_visible: true
    include_examples 'verify visibility in given state', state: :internal,  is_visible: false
    include_examples 'verify visibility in given state', state: :draft,     is_visible: false
    include_examples 'verify visibility in given state', state: :archived,  is_visible: false
  end

  describe '#internal_content?' do
    shared_examples 'verify visibility in given state' do |state:, is_visible:|
      it "returns #{is_visible} when contains #{state} answer" do
        object = create(:knowledge_base_category, "containing_#{state}")

        expect(object).send is_visible ? :to : :not_to, be_internal_content(object.translations.first.kb_locale)
      end
    end

    include_examples 'verify visibility in given state', state: :published, is_visible: true
    include_examples 'verify visibility in given state', state: :internal,  is_visible: true
    include_examples 'verify visibility in given state', state: :draft,     is_visible: false
    include_examples 'verify visibility in given state', state: :archived,  is_visible: false
  end
end
