# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
        categories_tree = @category.self_with_parents

        categories_with_permissions = KnowledgeBase::Category.where(id: categories_tree).includes(:permissions).to_a

        sorted_with_permissions = categories_tree
          .map { |elem| categories_with_permissions.find { |elem_with_permissions| elem_with_permissions == elem } }

        sorted_with_permissions + [@category.knowledge_base]
      end
    end
  end
end
