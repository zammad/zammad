# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase
  class InternalAssets
    CategoriesCache = Struct.new(:editor, :reader, :public_reader, keyword_init: true) do
      def all
        editor + reader + public_reader
      end
    end

    attr_reader :assets

    def initialize(user, answer_translation_content_ids: [])
      @user = user
      @assets = {}
      @answer_translation_content_ids = answer_translation_content_ids
    end

    def collect_assets
      collect_base_assets

      add_to_assets accessible_categories.all, type: :essential
      add_to_assets KnowledgeBase::Category::Translation.where(category: accessible_categories.all)

      collect_all_answer_assets

      @assets
    end

    def accessible_categories
      @accessible_categories ||= accessible_categories_calculate
    end

    def all_answer_ids
      all_answer_batches.each_with_object([]) do |elem, sum|
        sum.concat elem.pluck(:id)
      end
    end

    def all_category_ids
      accessible_categories.all.pluck(:id)
    end

    def visible_ids
      {
        answer_ids:   all_answer_ids,
        category_ids: all_category_ids
      }
    end

    private

    def accessible_categories_calculate
      struct = CategoriesCache.new editor: [], reader: [], public_reader: []

      KnowledgeBase::Category.all.find_in_batches do |group|
        group.each do |cat|
          case KnowledgeBase::EffectivePermission.new(@user, cat).access_effective
          when 'editor'
            struct.editor << cat
          when 'reader'
            struct.reader << cat if cat.internal_content?
          when 'public_reader'
            struct.public_reader << cat if cat.public_content?
          end
        end
      end

      struct
    end

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

    def all_answer_batches
      [
        KnowledgeBase::Answer.where(category: accessible_categories.editor),
        KnowledgeBase::Answer.internal.where(category: accessible_categories.reader),
        KnowledgeBase::Answer.published.where(category: accessible_categories.public_reader)
      ]
    end

    def collect_all_answer_assets
      all_answer_batches.each do |batch|
        collect_answers_assets batch
      end
    end

    def collect_answers_assets(scope)
      scope.find_in_batches do |group|
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
