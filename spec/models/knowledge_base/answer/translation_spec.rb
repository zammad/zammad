# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Answer::Translation, current_user_id: 1, type: :model do
  subject { create(:knowledge_base_answer_translation) }

  include_context 'factory'

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_uniqueness_of(:kb_locale_id).scoped_to(:answer_id).with_message(%r{}) }

  it { is_expected.to belong_to(:answer) }
  it { is_expected.to belong_to(:kb_locale) }

  describe '#edited_at' do
    let(:translation) { subject }

    before { translation } # create eagerly, before travel, so timestamps have a real gap to move across

    it 'is set on creation' do
      expect(translation.edited_at).to be_present
    end

    it 'updates when the title changes' do
      travel(1.hour) # time is frozen: if we don't travel forward, pre- and post-update values will be the same

      expect { translation.update!(title: 'Updated title') }
        .to change(translation, :edited_at)
    end

    it 'updates when the associated content body changes' do
      travel(1.hour) # time is frozen: if we don't travel forward, pre- and post-update values will be the same

      expect { translation.content.update!(body: 'Updated body') }
        .to change { translation.reload.edited_at }
    end

    it 'does not change when the translation is merely touched (e.g. via an unrelated answer change)' do
      travel(1.hour) # time is frozen: if we don't travel forward, pre- and post-update values will be the same

      expect { translation.answer.touch }
        .not_to change { translation.reload.edited_at }
    end
  end

  def handle_elasticsearch(enabled)
    if enabled
      searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
    else
      Setting.set('es_url', nil)
    end
  end

  describe '.search' do
    include_context 'basic Knowledge Base'

    [true, false].each do |elasticsearch|
      context "when ES=#{elasticsearch}", searchindex: elasticsearch do
        shared_examples 'verify given user' do |trait:, user_id:, is_visible:|
          prefix = is_visible ? 'lists' : 'does not list'

          it "#{prefix} #{trait} answer to #{user_id}" do
            user   = create(user_id)
            object = create(:knowledge_base_answer, trait, knowledge_base: knowledge_base)

            handle_elasticsearch(elasticsearch)

            expect(described_class.search({ query: object.translations.first.title, current_user: user })).to is_visible ? be_present : be_blank
          end
        end

        shared_examples 'verify given permissions' do |trait:, admin:, agent:, customer:|
          context "when permission is #{trait}" do
            include_examples 'verify given user', trait: trait, user_id: :admin,    is_visible: admin
            include_examples 'verify given user', trait: trait, user_id: :agent,    is_visible: agent
            include_examples 'verify given user', trait: trait, user_id: :customer, is_visible: customer
          end
        end

        describe 'non-granular permissions' do
          include_examples 'verify given permissions', trait: :published, admin: true, agent: true,  customer: false
          include_examples 'verify given permissions', trait: :internal,  admin: true, agent: true,  customer: false
          include_examples 'verify given permissions', trait: :draft,     admin: true, agent: false, customer: false
          include_examples 'verify given permissions', trait: :archived,  admin: true, agent: false, customer: false
        end

        describe 'multiple KBs support' do
          it 'searches in multiple KBs' do
            title = Faker::Appliance.equipment

            create_list(:knowledge_base_answer, 2, :published, translation_attributes: { title: title })

            handle_elasticsearch(elasticsearch)

            expect(described_class.search({ query: title, current_user: create(:admin) }).count).to be 2
          end
        end

        describe 'granular permissions' do
          let(:user) { create(:agent) }

          it 'returns given answer when granular permissions allow' do
            KnowledgeBase::PermissionsUpdate.new(internal_answer.category).update! user.roles.first => 'reader'
            handle_elasticsearch(elasticsearch)

            expect(described_class.search({ query: internal_answer.translations.first.title, current_user: user })).to be_present
          end

          it 'does not return given answer when granular permissions forbids' do
            KnowledgeBase::PermissionsUpdate.new(internal_answer.category).update! user.roles.first => 'none'
            handle_elasticsearch(elasticsearch)

            expect(described_class.search({ query: internal_answer.translations.first.title, current_user: user })).to be_blank
          end
        end
      end
    end
  end

  describe '#search_index_attribute_lookup' do
    include_context 'basic Knowledge Base'

    it 'sets search index attributes from translation and answer' do
      answer = create(:knowledge_base_answer, :published, :with_tag, tag_names: ['example-tag'], category: category)
      attrs  = answer.translations.first.search_index_attribute_lookup

      expect(attrs).to include(
        'title'             => answer.translations.first.title,
        'scope_id'          => category.id,
        'tags'              => include('example-tag'),
        'created_at'        => answer.translations.first.created_at,
        'updated_at'        => answer.translations.first.updated_at,
        'publication_state' => :published,
      )
    end

    describe 'answer state reflected in search index' do
      %i[draft internal published archived].each do |state|
        it "returns '#{state}' for #{state} answer" do
          answer = create(:knowledge_base_answer, state, category: category)
          attrs  = answer.translations.first.search_index_attribute_lookup

          expect(attrs['publication_state']).to eq(state)
        end
      end

      it 'is consistent with CanBePublished::StateMachine#calculated_state' do
        answer = create(:knowledge_base_answer, :published, category: category)
        attrs  = answer.translations.first.search_index_attribute_lookup

        expect(attrs['publication_state'])
          .to eq(answer.can_be_published_aasm.calculated_state)
      end
    end
  end

  describe '.vector_index_scope' do
    let(:knowledge_base)    { create(:knowledge_base) }
    let(:excluded_category) { create(:knowledge_base_category, knowledge_base:) }
    let(:sub_category)      { create(:knowledge_base_category, knowledge_base:, parent: excluded_category) }
    let(:kept_category)     { create(:knowledge_base_category, knowledge_base:) }

    let(:excluded_answer) { create(:knowledge_base_answer, :published, category: excluded_category) }
    let(:sub_answer)      { create(:knowledge_base_answer, :published, category: sub_category) }
    let(:kept_answer)     { create(:knowledge_base_answer, :published, category: kept_category) }

    def scoped_answer_ids
      described_class.vector_index_scope.map(&:answer_id)
    end

    before do
      excluded_answer
      sub_answer
      kept_answer
    end

    it 'covers every category while nothing is excluded' do
      expect(scoped_answer_ids).to include(excluded_answer.id, sub_answer.id, kept_answer.id)
    end

    context 'when a category is excluded' do
      before { Setting.set('vectordb_knowledge_base_excluded_category_ids', [excluded_category.id]) }

      it 'drops answers in the excluded category and its subtree', :aggregate_failures do
        expect(scoped_answer_ids).not_to include(excluded_answer.id)
        expect(scoped_answer_ids).not_to include(sub_answer.id)
      end

      it 'keeps answers outside the excluded subtree' do
        expect(scoped_answer_ids).to include(kept_answer.id)
      end
    end

    it 'covers any publication state, archived answers included' do
      archived = create(:knowledge_base_answer, :archived, category: kept_category)
      draft    = create(:knowledge_base_answer, :draft, category: kept_category)

      expect(scoped_answer_ids).to include(archived.id, draft.id)
    end

    it 'is empty when every category is excluded' do
      Setting.set('vectordb_knowledge_base_excluded_category_ids', KnowledgeBase::Category.pluck(:id))

      expect(described_class.vector_index_scope).to be_empty
    end
  end

  describe '#vector_index_data' do
    subject(:translation) { create(:knowledge_base_answer_translation) }

    it 'returns a hash with content, content_meta_headers, and metadata' do
      data = translation.vector_index_data

      expect(data).to be_a(Hash)
        .and have_key(:content)
        .and have_key(:content_meta_headers)
        .and have_key(:metadata)
    end

    it 'includes cleaned up content body' do
      translation.content.update(body: '<p>Test <b>content</b></p>')

      data = translation.vector_index_data

      expect(data[:content]).to eq('Test content')
    end

    it 'includes title in content_meta_headers' do
      data = translation.vector_index_data

      expect(data[:content_meta_headers]).to include(translation.title)
    end

    it 'includes locale in metadata' do
      data = translation.vector_index_data

      expect(data[:metadata][:locale]).to eq(translation.kb_locale.system_locale.locale)
    end

    it 'includes category_id in metadata' do
      data = translation.vector_index_data

      expect(data[:metadata][:category_id]).to eq(translation.answer.category_id)
    end

    it 'includes answer_id in metadata' do
      data = translation.vector_index_data

      expect(data[:metadata][:answer_id]).to eq(translation.answer_id)
    end
  end

  describe '#vector_indexing_for_record?' do
    let(:answer) { create(:knowledge_base_answer, :published) }

    it 'indexes an answer of a category that is not excluded' do
      expect(answer.translations.first).to be_vector_indexing_for_record
    end

    it 'indexes an archived answer, too' do
      archived = create(:knowledge_base_answer, :archived, category: answer.category)

      expect(archived.translations.first).to be_vector_indexing_for_record
    end

    it 'does not index an answer of an excluded category' do
      Setting.set('vectordb_knowledge_base_excluded_category_ids', [answer.category_id])

      expect(answer.translations.first).not_to be_vector_indexing_for_record
    end
  end
end
