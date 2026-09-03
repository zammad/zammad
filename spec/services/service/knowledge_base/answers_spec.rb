# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::Answers do
  subject(:answers) do
    described_class.with_current_user(user).execute(category:, locale:, sorting_mode:)
  end

  include_context 'basic Knowledge Base'

  let(:user)         { create(:admin) }
  let(:locale)       { primary_locale }
  let(:sorting_mode) { nil }

  before do
    published_answer
    internal_answer
    draft_answer
    archived_answer
  end

  context 'with an editor' do
    let(:user) { create(:admin) }

    it 'returns published, internal, draft and archived answers' do
      expect(answers).to contain_exactly(published_answer, internal_answer, draft_answer, archived_answer)
    end
  end

  context 'with a reader' do
    let(:user) { create(:agent) }

    it 'returns internal and published answers only' do
      expect(answers).to contain_exactly(published_answer, internal_answer)
    end
  end

  context 'with a public user' do
    let(:user) { create(:customer) }

    it 'returns published answers only' do
      expect(answers).to contain_exactly(published_answer)
    end
  end

  it 'lists the answers of the given category only' do
    expect(answers).not_to include(published_answer_in_other_category)
  end

  # Positions are not unique-constrained, so the id breaks the tie deterministically.
  context 'with answers sharing a position' do
    let(:user) { create(:admin) }

    before { KnowledgeBase::Answer.update_all(position: 1) }

    it 'orders them by position and then by id' do
      expect(answers.map(&:id)).to eq(answers.map(&:id).sort)
    end
  end

  # Mirrors the agent app: non-editors only see answers translated to the browsed locale, editors
  #   also see untranslated ones (their title falls back).
  context 'with an answer not translated to the browsed locale' do
    let(:untranslated_answer) do
      create(:knowledge_base_answer, :internal, category:, translation_attributes: { kb_locale: alternative_locale })
    end

    before { untranslated_answer }

    context 'with a reader' do
      let(:user) { create(:agent) }

      it 'hides the untranslated answer' do
        expect(answers).not_to include(untranslated_answer)
      end
    end

    context 'with an editor' do
      let(:user) { create(:admin) }

      it 'shows the untranslated answer' do
        expect(answers).to include(untranslated_answer)
      end
    end
  end

  describe 'sorting mode' do
    let(:user) { create(:admin) }

    # The shared context puts four more answers in the category, so assert on the relative order of
    #   the ones under test rather than on the whole list.
    def order_of(*records)
      answers.map(&:id) & records.map(&:id)
    end

    def answer_titled(title, kb_locale: primary_locale)
      create(:knowledge_base_answer, :published, category:, translation_attributes: { title:, kb_locale: })
    end

    context 'with the manual mode' do
      let(:first_answer)  { answer_titled('Zulu') }
      let(:second_answer) { answer_titled('Alpha') }

      before do
        first_answer
        second_answer
      end

      it 'keeps the hand-arranged positions' do
        second_answer.move_to_top

        expect(order_of(first_answer, second_answer)).to eq([second_answer.id, first_answer.id])
      end

      # acts_as_list already appends; this guards the story's "new items are added to the bottom".
      it 'appends a newly created answer' do
        expect(answers.map(&:id).last).to eq(second_answer.id)
      end

      # The category's two lists have a mode each: this listing reads `answer_sorting_mode` and must
      #   not be moved by the one its subcategories are listed in — the combination a single column
      #   could not express.
      it 'ignores the mode the subcategories are listed in' do
        category.update!(category_sorting_mode: 'alphabetical')
        second_answer.move_to_top

        expect(order_of(first_answer, second_answer)).to eq([second_answer.id, first_answer.id])
      end
    end

    context 'with the alphabetical mode' do
      let(:first_answer)  { answer_titled('Alpha') }
      let(:second_answer) { answer_titled('beta') }
      let(:third_answer)  { answer_titled('Gamma') }

      before do
        category.update!(answer_sorting_mode: 'alphabetical')

        third_answer
        first_answer
        second_answer
      end

      it 'orders by title, ignoring case' do
        expect(order_of(third_answer, second_answer, first_answer))
          .to eq([first_answer.id, second_answer.id, third_answer.id])
      end

      # Ordered by the database collation, which folds an accented title onto its base letter
      #   rather than filing it after "Zebra" the way a codepoint comparison would.
      context 'with non-ASCII titles' do
        let(:first_answer)  { answer_titled('Ähre') }
        let(:second_answer) { answer_titled('Šalis') }
        let(:third_answer)  { answer_titled('Zebra') }

        it 'folds accented titles onto their base letter' do
          expect(order_of(third_answer, second_answer, first_answer))
            .to eq([first_answer.id, second_answer.id, third_answer.id])
        end
      end

      # The title an answer is shown under is the one it has to sort under, so an answer missing a
      #   translation in the browsed locale sorts under the primary-locale title that is displayed.
      context 'with an answer untranslated in the browsed locale' do
        let(:locale)              { alternative_locale }
        let(:translated_answer)   { answer_titled('Zulu', kb_locale: alternative_locale) }
        let(:untranslated_answer) { answer_titled('Delta') }

        before do
          translated_answer
          untranslated_answer
        end

        it 'sorts it under its fallback title' do
          expect(order_of(translated_answer, untranslated_answer))
            .to eq([untranslated_answer.id, translated_answer.id])
        end
      end
    end

    # What the sorting bar previews with: the listing is fetched in the mode the editor picked, so
    #   what they see before saving is the very order saving produces.
    context 'with a previewed sorting mode' do
      let(:first_answer)  { answer_titled('Zulu') }
      let(:second_answer) { answer_titled('Alpha') }

      before do
        first_answer
        second_answer
        second_answer.move_to_bottom
      end

      context 'when it differs from the stored one' do
        let(:sorting_mode) { 'alphabetical' }

        it 'lists in the previewed mode' do
          expect(order_of(first_answer, second_answer)).to eq([second_answer.id, first_answer.id])
        end

        it 'leaves the stored mode alone' do
          answers.to_a

          expect(category.reload.answer_sorting_mode).to eq('manual')
        end
      end

      # Nothing to preview is the ordinary case, and every other caller of this service — the
      #   answer navigation, the public help site — passes none.
      context 'when none is given' do
        it 'lists in the stored mode' do
          expect(order_of(first_answer, second_answer)).to eq([first_answer.id, second_answer.id])
        end
      end
    end

    # Dates an answer the way the interface does: the later of its publication and the edit date of
    #   the translation shown, so an answer edited before it went live is dated by going live.
    context 'with the last update mode' do
      let(:first_answer)  { answer_titled('Alpha') }
      let(:second_answer) { answer_titled('Beta') }
      let(:third_answer)  { answer_titled('Gamma') }

      before do
        category.update!(answer_sorting_mode: 'last_update')

        first_answer
        second_answer
        third_answer

        travel_to(1.hour.from_now)  { second_answer.translation.update!(title: 'Beta, edited') }
        travel_to(2.hours.from_now) { first_answer.translation.update!(title: 'Alpha, edited') }
      end

      it 'orders by the most recently edited first' do
        expect(order_of(first_answer, second_answer, third_answer))
          .to eq([first_answer.id, second_answer.id, third_answer.id])
      end

      # A tag or a category move touches the translation row but is not an editorial change, so it
      #   must not reorder the list — which is why this sorts on edited_at, not on updated_at.
      it 'ignores a change that is not an edit' do
        travel_to(3.hours.from_now) { third_answer.tag_add('example_kb_tag') }

        expect(order_of(first_answer, second_answer, third_answer))
          .to eq([first_answer.id, second_answer.id, third_answer.id])
      end

      it 'dates an answer edited before publication by its publication' do
        published_later = answer_titled('Delta')
        travel_to(3.hours.from_now) { published_later.update!(published_at: Time.zone.now) }

        expect(order_of(published_later, first_answer)).to eq([published_later.id, first_answer.id])
      end

      # The internal listing dates an answer from whichever came first, so an answer published
      #   internally long before it went public sorts by the internal date.
      it 'uses the earlier of the internal and public publication' do
        internal_first = answer_titled('Epsilon')
        internal_first.update!(internal_at: 10.days.ago, published_at: 10.minutes.ago)

        expect(order_of(internal_first, first_answer)).to eq([first_answer.id, internal_first.id])
      end
    end
  end

  # Usable without a user at all, which is what the public help site browses with.
  context 'without a current user' do
    subject(:answers) { described_class.execute(category:, locale:) }

    it 'returns the published answers' do
      expect(answers).to contain_exactly(published_answer)
    end
  end
end
