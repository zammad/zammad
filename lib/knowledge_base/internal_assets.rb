# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase
  class InternalAssets
    attr_reader :assets

    def initialize(user, categories_filter: [], answer_translation_content_ids: [])
      @user = user
      @assets = {}
      @categories_filter = categories_filter
      @answer_translation_content_ids = answer_translation_content_ids
    end

    def collect_assets
      collect_base_assets

      add_to_assets accessible_categories.visible, type: :essential
      add_to_assets KnowledgeBase::Category::Translation.where(category: accessible_categories.visible)

      collect_answers_assets

      @assets
    end

    def accessible_categories
      @accessible_categories ||= KnowledgeBase::AccessibleCategories
        .for_user(@user, categories_filter: @categories_filter)
    end

    def all_answer_ids
      all_answers.pluck(:id)
    end

    def all_category_ids
      accessible_categories.visible.pluck(:id)
    end

    def visible_ids
      {
        answer_ids:   all_answer_ids,
        category_ids: all_category_ids
      }
    end

    private

    def add_to_assets(objects, type: nil)
      @assets = ApplicationModel::CanAssets.reduce(objects, @assets, type)
    end

    def collect_base_assets
      [KnowledgeBase, KnowledgeBase::Translation, KnowledgeBase::Locale]
        .each do |klass|
          klass.find_in_batches do |group|
            add_to_assets group, type: :essential
          end
        end
    end

    def all_answers
      KnowledgeBase::Answer.visible_by_categories(accessible_categories)
    end

    def collect_answers_assets
      all_answers.find_in_batches do |group|
        add_to_assets group, type: :essential

        translations = KnowledgeBase::Answer::Translation.where(answer: group)

        add_to_assets translations, type: :essential

        if @answer_translation_content_ids.present?
          contents = KnowledgeBase::Answer::Translation::Content
            .joins(:translation)
            .where(
              id:                                 @answer_translation_content_ids,
              knowledge_base_answer_translations: { answer_id: group }
            )

          add_to_assets contents
        end
      end
    end
  end
end
