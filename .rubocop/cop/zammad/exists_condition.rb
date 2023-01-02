# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      # This cop is used to identify usages of `find_by` in conditions and
      # changes them to use `exists?` instead.
      #
      # @example
      #   # bad
      #   if User.find_by(name: 'Rubocop')
      #   if !User.find_by(name: 'Rubocop')
      #   unless User.find_by(name: 'Rubocop')
      #   if find_by(name: 'Rubocop')
      #   if !find_by(name: 'Rubocop')
      #   unless find_by(name: 'Rubocop')
      #
      #   # good
      #   if User.exists?(name: 'Rubocop')
      #   if !User.exists?(name: 'Rubocop')
      #   unless User.exists?(name: 'Rubocop')
      #   if exists?(name: 'Rubocop')
      #   if !exists?(name: 'Rubocop')
      #   unless exists?(name: 'Rubocop')
      class ExistsCondition < Base

        def_node_matcher :find_by_condition?, <<-PATTERN
          {
            $(send $_ :find_by ...)
            (send $(send $_ :find_by ...) :!)
          }
        PATTERN

        MSG = 'Use `%<prefer>s` instead of `%<current>s`.'.freeze

        def on_if(node)
          check_for_find_by(node)
        end

        def on_while(node)
          check_for_find_by(node)
        end

        def on_while_post(node)
          check_for_find_by(node)
        end

        def on_until(node)
          check_for_find_by(node)
        end

        def on_until_post(node)
          check_for_find_by(node)
        end

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node.loc.selector, 'exists?')
          end
        end

        private

        def check_for_find_by(node)
          cond = condition(node)
          handle_node(cond)
        end

        def check_node(node)
          return if !node

          if keyword_bang?(node)
            receiver, = *node

            handle_node(receiver)
          elsif node.operator_keyword?
            node.each_child_node { |op| handle_node(op) }
          elsif node.begin_type? && node.children.one?
            handle_node(node.children.first)
          end
        end

        def keyword_bang?(node)
          node.respond_to?(:keyword_bang?) && node.keyword_bang?
        end

        def handle_node(node)
          if node.send_type?
            check_offense(*find_by_condition?(node))
          elsif %i[and or begin].include?(node.type)
            check_node(node)
          end
        end

        def condition(node)
          if node.send_type?
            node.receiver
          else
            node.condition
          end
        end

        def check_offense(method_call = nil, receiver = nil)
          return if method_call.nil?

          add_offense(method_call,
                      message: format(MSG,
                                      prefer:  replacement(receiver),
                                      current: current(receiver)))
        end

        def current(node)
          node.respond_to?(:source) ? "#{node.source}.find_by" : 'find_by'
        end

        def replacement(node)
          node.respond_to?(:source) ? "#{node.source}.exists?" : 'exists?'
        end
      end
    end
  end
end
