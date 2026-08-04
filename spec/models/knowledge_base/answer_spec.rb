# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/checks_kb_client_notification_examples'
require 'models/concerns/has_tags_examples'
require 'models/concerns/has_translations_examples'
require 'models/contexts/factory_context'
require 'models/concerns/can_lookup_search_index_attributes_with_attachments_examples'

RSpec.describe KnowledgeBase::Answer, current_user_id: 1, type: :model do
  subject(:kb_answer) { create(:knowledge_base_answer) }

  it_behaves_like 'HasTags'
  it_behaves_like 'CanLookupSearchIndexAttributesWithAttachments'

  include_context 'factory'

  it_behaves_like 'ChecksKbClientNotification'

  describe 'HasTranslations' do
    include_context 'basic Knowledge Base'

    let!(:record) { create(:knowledge_base_answer, category:) }
    let(:add_translation) do
      ->(locale) { create(:knowledge_base_answer_translation, answer: record, kb_locale: locale) }
    end

    it_behaves_like 'HasTranslations'
  end

  it { is_expected.not_to validate_presence_of(:category_id) }
  it { is_expected.to belong_to(:category) }
  it { expect(kb_answer.attachments).to be_blank }

  context 'with attachment' do
    subject(:kb_answer) { create(:knowledge_base_answer, :with_attachment) }

    it { expect(kb_answer.attachments).to be_present }
  end

  describe '#assets', current_user_id: -> { user.id } do
    let(:assets)                  { another_category_answer && internal_answer.assets }
    let(:user)                    { create(:agent) }
    let(:another_category)        { create(:knowledge_base_category, knowledge_base: knowledge_base) }
    let(:another_category_answer) { create(:knowledge_base_answer, :internal, category: another_category) }

    include_context 'basic Knowledge Base'

    context 'without permissions' do
      it { expect(assets).to include_assets_of internal_answer }
      it { expect(assets).to include_assets_of category }
    end

    context 'with readable another category' do
      before do
        KnowledgeBase::PermissionsUpdate
          .new(another_category)
          .update! user.roles.first => 'reader'
      end

      it { expect(assets).to include_assets_of internal_answer }
      it { expect(assets).to include_assets_of category }
    end

    context 'with hidden another category' do
      before do
        KnowledgeBase::PermissionsUpdate
          .new(another_category)
          .update! user.roles.first => 'none'
      end

      it { expect(assets).to include_assets_of internal_answer }
      it { expect(assets).to include_assets_of category }

      context 'with published answer' do
        let(:another_category_published_answer) { create(:knowledge_base_answer, :published, category: another_category) }

        before { another_category_published_answer }

        it { expect(assets).to include_assets_of internal_answer }
        it { expect(assets).to include_assets_of category }
      end
    end
  end

  describe '#sorted_by_published' do
    it 'sorts by publishing or translation edit date, whichever is greater' do
      described_class.destroy_all

      knowledge_base = create(:knowledge_base)
      system_locale  = knowledge_base.kb_locales.first.system_locale

      answer1 = create(:knowledge_base_answer, knowledge_base: knowledge_base, published_at: 1.day.ago)
      answer1.translation.update! edited_at: 1.day.ago
      answer2 = create(:knowledge_base_answer, knowledge_base: knowledge_base, published_at: 1.day.ago)
      answer2.translation.update! edited_at: 1.hour.ago
      answer3 = create(:knowledge_base_answer, knowledge_base: knowledge_base, published_at: 1.minute.ago)
      answer3.translation.update! edited_at: 1.day.ago

      expect(described_class.sorted_by_published(system_locale)).to contain_exactly(answer3, answer1, answer2)
    end
  end

  describe '#sorted_by_internally_published' do
    it 'sorts by internally publishing or translation edit date, whichever is greater' do
      described_class.destroy_all

      knowledge_base = create(:knowledge_base)
      system_locale  = knowledge_base.kb_locales.first.system_locale

      answer1 = create(:knowledge_base_answer, knowledge_base: knowledge_base, internal_at: 2.days.ago, published_at: 1.day.ago)
      answer1.translation.update! edited_at: 2.days.ago
      answer2 = create(:knowledge_base_answer, knowledge_base: knowledge_base, published_at: 1.day.ago)
      answer2.translation.update! edited_at: 1.hour.ago
      answer3 = create(:knowledge_base_answer, knowledge_base: knowledge_base, published_at: 30.minutes.ago)
      answer3.translation.update! edited_at: 1.day.ago
      answer4 = create(:knowledge_base_answer, knowledge_base: knowledge_base, internal_at: 1.minute.ago)
      answer4.translation.update! edited_at: 1.day.ago
      answer5 = create(:knowledge_base_answer, knowledge_base: knowledge_base, published_at: 1.week.ago, internal_at: nil)
      answer5.translation.update! edited_at: 1.week.ago
      _answer6 = create(:knowledge_base_answer, knowledge_base: knowledge_base, internal_at: nil, published_at: nil)

      expect(described_class.sorted_by_internally_published(system_locale)).to contain_exactly(answer4, answer3, answer1, answer2, answer5)
    end
  end

  describe '.visible_by_categories' do
    include_context 'basic Knowledge Base'
    let(:struct) { KnowledgeBase::AccessibleCategories::CategoriesStruct.new }

    before do
      published_answer
      internal_answer
      draft_answer
      published_answer_in_other_category
      internal_answer_in_other_category
    end

    it 'returns any article in editor categories' do
      struct.editor = [category]

      expect(described_class.visible_by_categories(struct))
        .to contain_exactly(published_answer, internal_answer, draft_answer)
    end

    it 'returns internal and published answers in reader categories' do
      struct.reader = [category]

      expect(described_class.visible_by_categories(struct))
        .to contain_exactly(published_answer, internal_answer)
    end

    it 'returns only public answers in public reader categories' do
      struct.public_reader = [category]

      expect(described_class.visible_by_categories(struct))
        .to contain_exactly(published_answer)
    end

    it 'returns correct answers with a combination of categories' do
      struct.editor = [other_category]
      struct.reader = [category]

      expect(described_class.visible_by_categories(struct))
        .to contain_exactly(
          published_answer, internal_answer, published_answer_in_other_category, internal_answer_in_other_category
        )
    end
  end

  describe 'visible_to_user' do
    include_context 'basic Knowledge Base'

    before do
      published_answer
      internal_answer
      draft_answer
      internal_answer_in_other_category
      draft_answer_in_other_category
    end

    context 'when granular permissions enabled' do
      before do
        next if !defined?(access)

        KnowledgeBase::PermissionsUpdate
          .new(category)
          .update! user.roles.first => access
      end

      context 'when user is editor' do
        let(:user) { create(:admin_only) }

        context 'when user has specified editor access to one category' do
          let(:access) { 'editor' }

          it 'returns accessible answers' do
            expect(described_class.visible_to_user(user)).to contain_exactly(
              published_answer, internal_answer, draft_answer,
              internal_answer_in_other_category, draft_answer_in_other_category
            )
          end
        end

        context 'when user has specified reader access to one category' do
          let(:access) { 'reader' }

          it 'returns accessible answers' do
            expect(described_class.visible_to_user(user)).to contain_exactly(
              published_answer, internal_answer,
              internal_answer_in_other_category, draft_answer_in_other_category
            )
          end
        end

        context 'when user has specified no access to one category' do
          let(:access) { 'none' }

          it 'returns accessible answers' do
            expect(described_class.visible_to_user(user)).to contain_exactly(
              published_answer,
              internal_answer_in_other_category, draft_answer_in_other_category
            )
          end
        end
      end

      context 'when user is reader' do
        let(:user) { create(:agent) }

        context 'when user has specified reader access to one category' do
          let(:access) { 'reader' }

          it 'returns accessible answers' do
            expect(described_class.visible_to_user(user)).to contain_exactly(
              published_answer, internal_answer, internal_answer_in_other_category
            )
          end
        end

        context 'when user has specified no access to one category' do
          let(:access) { 'none' }

          it 'returns accessible answers' do
            expect(described_class.visible_to_user(user)).to contain_exactly(
              published_answer, internal_answer_in_other_category
            )
          end
        end
      end

      context 'when user is a guest' do
        let(:user) { create(:customer) }

        context 'when user has public access' do
          it 'returns published answers for public reader' do
            expect(described_class.visible_to_user(user)).to contain_exactly(
              published_answer
            )
          end

          it 'does not call visible_by_categories' do
            allow(described_class).to receive(:visible_by_categories)

            described_class.visible_to_user(user)

            expect(described_class).not_to have_received(:visible_by_categories)
          end
        end
      end
    end

    context 'when granular permissions not enabled' do
      context 'when user is editor' do
        let(:user) { create(:admin) }

        it 'returns all answers for editor' do
          expect(described_class.visible_to_user(user)).to contain_exactly(
            published_answer, internal_answer, draft_answer,
            internal_answer_in_other_category, draft_answer_in_other_category
          )
        end

        it 'does not call visible_by_categories' do
          allow(described_class).to receive(:visible_by_categories)

          described_class.visible_to_user(user)

          expect(described_class).not_to have_received(:visible_by_categories)
        end
      end

      context 'when user is reader' do
        let(:user) { create(:agent) }

        it 'returns internal answers for reader' do
          expect(described_class.visible_to_user(user)).to contain_exactly(
            published_answer, internal_answer,
            internal_answer_in_other_category
          )
        end

        it 'does not call visible_by_categories' do
          allow(described_class).to receive(:visible_by_categories)

          described_class.visible_to_user(user)

          expect(described_class).not_to have_received(:visible_by_categories)
        end
      end

      context 'when user is public reader' do
        let(:user) { create(:customer) }

        it 'returns published answers for public reader' do
          expect(described_class.visible_to_user(user)).to contain_exactly(
            published_answer
          )
        end

        it 'does not call visible_by_categories' do
          allow(described_class).to receive(:visible_by_categories)

          described_class.visible_to_user(user)

          expect(described_class).not_to have_received(:visible_by_categories)
        end
      end

      context 'when user not given' do
        it 'returns published answers for public reader' do
          expect(described_class.visible_to_user(nil)).to contain_exactly(
            published_answer
          )
        end

        it 'does not call visible_by_categories' do
          allow(described_class).to receive(:visible_by_categories)

          described_class.visible_to_user(nil)

          expect(described_class).not_to have_received(:visible_by_categories)
        end
      end
    end
  end

  describe 'reindexing translations when the answer changes', performs_jobs: true do
    before do
      allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(true)
      allow(Service::AI::VectorDB::Document::Upsert).to receive(:execute)
      allow(Service::AI::VectorDB::Document::Destroy).to receive(:execute)
    end

    # Regression: the metadata after_commit used to touch the translations, which touch the answer
    # back via `belongs_to :answer, touch: true`, re-entering the answer callbacks and recursing
    # without bound (SystemStackError).
    it 'does not recurse while indexing a newly published answer' do
      expect { create(:knowledge_base_answer, :published) }.not_to raise_error
    end

    it 'does not recurse on a later metadata change' do
      answer       = create(:knowledge_base_answer, :published)
      new_category = create(:knowledge_base_category, knowledge_base: answer.category.knowledge_base)

      expect { answer.update!(category: new_category) }.not_to raise_error
    end

    it 'enqueues a reindex for each indexed translation', :aggregate_failures do
      knowledge_base     = create(:knowledge_base)
      alternative_locale = create(:knowledge_base_locale, knowledge_base:, system_locale: Locale.find_by(locale: 'lt'))
      new_category       = create(:knowledge_base_category, knowledge_base:)
      answer             = create(:knowledge_base_answer, :published, category: create(:knowledge_base_category, knowledge_base:))
      create(:knowledge_base_answer_translation, answer:, kb_locale: alternative_locale)

      # A fresh instance, as a later request would load it. Regression: freshly loaded translations
      # carry no previous_changes (their touch is a touch_later), so the reindex decision must come
      # from the relevant-change check alone — a previous_changes guard would silently skip them.
      answer = described_class.find(answer.id)

      # Drop anything enqueued during setup so the expectations only see jobs from the update below.
      clear_jobs
      answer.update!(category: new_category)

      expect(answer.translations.reload.count).to be > 1
      answer.translations.each do |translation|
        expect(VectorIndexJob).to have_been_enqueued.with('KnowledgeBase::Answer::Translation', translation.id)
      end
    end

    # An answer change that doesn't feed the vector document (e.g. the internal note) still touches
    # the translations to refresh the search index, but must not trigger a vector reindex.
    it 'does not enqueue a reindex on a vector-irrelevant answer change' do
      answer = create(:knowledge_base_answer, :published)

      # A fresh instance, as a later request would load it. (On instances kept from creation the
      # translations still carry their creation previous_changes, which errs towards reindexing.)
      answer = described_class.find(answer.id)

      # Without this the creation job stays pending and HasActiveJobLock would coalesce a wrongly
      # enqueued reindex into it, letting this expectation pass for the wrong reason.
      clear_jobs

      expect { answer.update!(internal_note: 'changed') }.not_to have_enqueued_job(VectorIndexJob)
    end

    # Regression: the title edit's touch of the answer makes the answer touch the translation back.
    # touch_translations uses touch_later, so the translation keeps previous_changes=[title] and the
    # reindex fires — an immediate touch would reset them and the title change would be skipped.
    it 'enqueues a reindex on a title change' do
      answer = create(:knowledge_base_answer, :published)

      # Every category is indexed by default, so creating the answer already enqueued a reindex for
      # this translation. VectorIndexJob coalesces per record (HasActiveJobLock), so that pending job
      # would swallow the enqueue this example is asserting on.
      clear_jobs

      expect { answer.translations.first.update!(title: 'A different title') }
        .to have_enqueued_job(VectorIndexJob).with('KnowledgeBase::Answer::Translation', answer.translations.first.id)
    end

    it 'enqueues a reindex on a title change combined with a vector-irrelevant answer change' do
      answer      = create(:knowledge_base_answer, :published)
      translation = answer.translations.first
      clear_jobs

      expect { answer.update!(internal_note: 'note', translations_attributes: [{ id: translation.id, title: 'Combined title' }]) }
        .to have_enqueued_job(VectorIndexJob).with('KnowledgeBase::Answer::Translation', translation.id)
    end

    it 'enqueues a reindex on a body change' do
      answer = create(:knowledge_base_answer, :published)
      clear_jobs

      expect { answer.translations.first.content.update!(body: '<p>new body</p>') }
        .to have_enqueued_job(VectorIndexJob).with('KnowledgeBase::Answer::Translation', answer.translations.first.id)
    end

    it 'does not enqueue a reindex for translations in an excluded category' do
      answer            = create(:knowledge_base_answer, :published)
      excluded_category = create(:knowledge_base_category, knowledge_base: answer.category.knowledge_base)
      Setting.set('vectordb_knowledge_base_excluded_category_ids', [excluded_category.id])
      clear_jobs

      expect { answer.update!(category: excluded_category) }
        .not_to have_enqueued_job(VectorIndexJob)
    end

    # Regression: the indexing decision runs from an after_commit, so an unusable value in the
    # exclusion setting used to raise NoMethodError out of every answer save, not just out of the
    # vector index.
    it 'still saves when the excluded category setting holds an unusable value' do
      answer = create(:knowledge_base_answer, :published)
      Setting.set('vectordb_knowledge_base_excluded_category_ids', 'nonsense')

      expect { answer.update!(internal_note: 'changed') }.not_to raise_error
    end

    # Regression: a job enqueued while the record was indexable must not re-upsert it if the record
    # became non-indexable before the job ran — it removes the stale document instead.
    it 'removes instead of upserting when the record is no longer indexable at run time', :aggregate_failures do
      answer      = create(:knowledge_base_answer, :published)
      translation = answer.translations.first
      allow(translation).to receive(:vector_index_destroy)

      # The record turned non-indexable (its category was excluded) after the reindex job was enqueued.
      Setting.set('vectordb_knowledge_base_excluded_category_ids', [answer.category_id])

      translation.vector_index_update

      expect(translation).to have_received(:vector_index_destroy)
      expect(Service::AI::VectorDB::Document::Upsert).not_to have_received(:execute)
    end
  end

  describe 'triggering search indexes' do
    context 'when answer is updated' do
      let(:answer)      { create(:knowledge_base_answer) }
      let(:translation) { answer.translations.first }

      before do
        allow(translation).to receive(:search_index_update)
      end

      it 'triggers translation re-indexing' do
        answer.update!(category: create(:knowledge_base_category))

        expect(translation).to have_received(:search_index_update)
      end
    end
  end
end
