# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Category::Translation, type: :model do
  subject { create(:knowledge_base_category_translation) }

  include_context 'factory'

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_uniqueness_of(:kb_locale_id).scoped_to(:category_id).with_message(%r{}) }

  it { is_expected.to belong_to(:category) }
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

    # The editorial contract: everything that reaches this row without being an edit does so through
    #   `touch`, which runs no callbacks at all.
    it 'does not change when the translation is merely touched (e.g. via an unrelated category change)' do
      travel(1.hour)

      expect { translation.category.touch }
        .not_to change { translation.reload.edited_at }
    end

    it 'does not change when the category is reordered' do
      travel(1.hour)

      expect { translation.category.update!(position: 5) }
        .not_to change { translation.reload.edited_at }
    end

    it 'does not change when the category switches sorting mode' do
      travel(1.hour)

      expect { translation.category.update!(category_sorting_mode: 'last_update') }
        .not_to change { translation.reload.edited_at }
    end
  end

  # A category is dated by the content below it, so an edit anywhere in a subtree is an edit of every
  #   category above it — in the locale(s) that edit happened in, and in no other.
  describe 'bumping the editorial timestamp up the tree' do
    let(:knowledge_base)    { create(:knowledge_base) }
    let(:primary_locale)    { knowledge_base.translation_primary.kb_locale }
    let(:secondary_locale)  { create(:knowledge_base_locale, knowledge_base:, system_locale: Locale.find_by(locale: 'lt')) }

    # Three levels, two locales — except the middle one, which is only translated to the primary
    #   locale. It is listed under a fallback title, so an edit in the secondary locale is not an
    #   edit of anything it shows, and it has to be left alone.
    let(:root)   { create_category(parent: nil, locales: [primary_locale, secondary_locale]) }
    let(:middle) { create_category(parent: root, locales: [primary_locale]) }
    let(:leaf)   { create_category(parent: middle, locales: [primary_locale, secondary_locale]) }

    def create_category(parent:, locales:)
      create(:knowledge_base_category, knowledge_base:, parent:, translations: locales.map { |kb_locale| build(:knowledge_base_category_translation, kb_locale:) })
    end

    def edited_at_of(category, kb_locale)
      category.translations.reload.find { |translation| translation.kb_locale_id == kb_locale.id }&.edited_at
    end

    # The whole tree, so one expectation can name what moved *and* what did not.
    def timestamps
      {
        root_primary:   edited_at_of(root, primary_locale),
        root_secondary: edited_at_of(root, secondary_locale),
        middle_primary: edited_at_of(middle, primary_locale),
        leaf_primary:   edited_at_of(leaf, primary_locale),
        leaf_secondary: edited_at_of(leaf, secondary_locale),
      }
    end

    # Everything is built (and has bumped its ancestors) before the clock moves, so any later change
    #   is unambiguous.
    def later(&)
      travel_to(1.hour.from_now, &)
    end

    before { leaf } # builds the whole chain

    context 'when a category title is written' do
      it 'moves the category and all its ancestors, in that translation\'s locale only' do
        before_bump = timestamps

        later { leaf.translation_to(secondary_locale).update!(title: 'Edited') }

        expect(timestamps).to include(
          leaf_secondary: be > before_bump[:leaf_secondary],
          root_secondary: be > before_bump[:root_secondary],
          leaf_primary:   eq(before_bump[:leaf_primary]),
          root_primary:   eq(before_bump[:root_primary]),
        )
      end

      # The one ancestor with no row in the edited locale: there is nothing of it that this edit
      #   changed, so its own locale must not move either.
      it 'leaves an ancestor without a translation in that locale alone' do
        expect { later { leaf.translation_to(secondary_locale).update!(title: 'Edited') } }
          .not_to change { edited_at_of(middle, primary_locale) }
      end

      # A new locale is a title written for the first time, so it counts exactly as a changed one —
      #   `middle` is the category still missing that translation.
      it 'moves the ancestors when a category is translated to a new locale' do
        expect { later { create(:knowledge_base_category_translation, category: middle, kb_locale: secondary_locale, title: 'New locale') } }
          .to change { edited_at_of(root, secondary_locale) }
      end
    end

    context 'when an answer is edited' do
      let(:answer) { create(:knowledge_base_answer, category: leaf, translation_attributes: { kb_locale: secondary_locale }) }

      before { answer }

      it 'moves the answer\'s category and all its ancestors, in the answer translation\'s locale only' do
        before_bump = timestamps

        later { answer.translation.update!(title: 'Edited') }

        expect(timestamps).to include(
          leaf_secondary: be > before_bump[:leaf_secondary],
          root_secondary: be > before_bump[:root_secondary],
          leaf_primary:   eq(before_bump[:leaf_primary]),
          root_primary:   eq(before_bump[:root_primary]),
        )
      end

      it 'moves them when the body changes' do
        expect { later { answer.translation.content.update!(body: 'Edited body') } }
          .to change { edited_at_of(root, secondary_locale) }
      end

      it 'moves them when the answer is created' do
        expect { later { create(:knowledge_base_answer, category: leaf, translation_attributes: { kb_locale: secondary_locale, title: 'Brand new' }) } }
          .to change { edited_at_of(root, secondary_locale) }
      end

      # Everything that reaches an answer translation without being an editorial change goes through
      #   `touch`, which runs no callbacks — so this holds by construction rather than by a filter.
      it 'does not move them for a tag, an attachment or a publication change', :aggregate_failures do
        expect { later { answer.tag_add('example_kb_tag', 1) } }
          .not_to change { edited_at_of(root, secondary_locale) }
        expect { later { create(:store, object: 'KnowledgeBase::Answer', o_id: answer.id, data: 'file', filename: 'example.txt') } }
          .not_to change { edited_at_of(root, secondary_locale) }
        expect { later { answer.update!(published_at: Time.zone.now) } }
          .not_to change { edited_at_of(root, secondary_locale) }
      end
    end

    context 'when an answer is moved' do
      let(:answer)     { create(:knowledge_base_answer, category: leaf) }
      let(:other_root) { create_category(parent: nil, locales: [primary_locale, secondary_locale]) }

      before { answer && other_root }

      it 'moves the new category and its ancestors' do
        expect { later { answer.update!(category: other_root) } }
          .to change { edited_at_of(other_root, primary_locale) }
      end

      it 'leaves the category it came out of alone', :aggregate_failures do
        before_bump = timestamps

        later { answer.update!(category: other_root) }

        expect(timestamps).to eq(before_bump)
      end

      it 'carries every locale the answer is translated to' do
        create(:knowledge_base_answer_translation, answer:, kb_locale: secondary_locale)

        expect { later { answer.update!(category: other_root) } }
          .to change { edited_at_of(other_root, secondary_locale) }
      end

      it 'bumps nothing when it is destroyed' do
        before_bump = timestamps

        later { answer.destroy! }

        expect(timestamps).to eq(before_bump)
      end
    end

    context 'when a category is moved' do
      let(:other_root) { create_category(parent: nil, locales: [primary_locale, secondary_locale]) }

      before { other_root }

      it 'moves the new parent and its ancestors, in every locale the moved category has' do
        before_bump = { primary: edited_at_of(other_root, primary_locale), secondary: edited_at_of(other_root, secondary_locale) }

        later { leaf.update!(parent: other_root) }

        expect({ primary: edited_at_of(other_root, primary_locale), secondary: edited_at_of(other_root, secondary_locale) })
          .to match(primary: be > before_bump[:primary], secondary: be > before_bump[:secondary])
      end

      # Being moved is not being edited, and neither is losing a subtree.
      it 'leaves the moved category and the parent it came out of alone' do
        before_bump = timestamps

        later { leaf.update!(parent: other_root) }

        expect(timestamps).to eq(before_bump)
      end

      it 'bumps nothing when the category moves to the top level' do
        before_bump = timestamps

        later { leaf.update!(parent: nil) }

        expect(timestamps).to eq(before_bump)
      end
    end
  end
end
