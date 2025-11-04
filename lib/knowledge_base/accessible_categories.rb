# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase
  class AccessibleCategories
    CategoriesStruct = Struct.new(:editor, :reader, :public_reader, keyword_init: true) do
      def initialize(editor: [], reader: [], public_reader: [])
        super
      end

      def visible
        editor + reader + public_reader
      end

      def internally_visible
        editor + reader
      end
    end

    attr_reader :user, :categories_filter

    def initialize(user, categories_filter: nil)
      @user = user
      @categories_filter = categories_filter
    end

    def calculate
      struct = CategoriesStruct.new editor: [], reader: [], public_reader: []

      scope.each do |group|
        group.each do |category|
          taxonomize_category(struct, category)
        end
      end

      struct
    end

    def self.for_user(user, categories_filter: nil)
      Rails.cache.fetch(cache_key(user, categories_filter:)) do
        new(user, categories_filter:).calculate
      end
    end

    # Cache key is bumped even if changes are outside filtered tree
    # It would be much slower to calculate the fingerprint for filtered tree
    def self.cache_key(user, categories_filter: nil)
      fingerprint = Digest::MD5.hexdigest({
        role_ids:                 user.role_ids.sort,
        categories_filter:        Array(categories_filter).map(&:id).sort,
        category_cache_version:   KnowledgeBase::Category.all.cache_version,
        permission_cache_version: KnowledgeBase::Permission.all.cache_version,
      }.to_s)

      "kb-categories-accessible-#{fingerprint}"
    end

    private

    def scope
      return KnowledgeBase::Category.find_in_batches if categories_filter.blank?

      Array(categories_filter)
        .map(&:self_with_children)
        .each
    end

    def taxonomize_category(struct, category)
      case KnowledgeBase::EffectivePermission.new(user, category).access_effective
      when 'editor'
        struct.editor << category
      when 'reader'
        struct.reader << category if category.internal_content?
      when 'public_reader'
        struct.public_reader << category if category.public_content?
      end
    end
  end
end
