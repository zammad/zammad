# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      module CanCheckNamespace
        def namespace_path(node)
          node.each_ancestor(:class, :module).filter_map do |ancestor|
            ancestor.identifier&.const_name
          end
        end

        def inside_namespace?(node, *namespaces)
          path = namespace_path(node).reverse.join('::')

          namespaces.any? { |ns| path.start_with?(ns) }
        end
      end
    end
  end
end
