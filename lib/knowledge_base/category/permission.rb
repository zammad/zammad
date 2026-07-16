# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase
  class Category
    class Permission
      def initialize(category)
        @category = category
      end

      def permissions_effective
        parents_for_category
          .map(&:permissions)
          .flatten
          .each_with_object([]) do |elem, memo|
            memo << elem if !memo.find { |added| added.role == elem.role }
          end
      end

      private

      def parents_for_category
        @category.self_with_parents.includes(:permissions).to_a + [@category.knowledge_base]
      end
    end
  end
end
