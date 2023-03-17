# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class DetectTranslatableString < Base
        extend AutoCorrector

        MSG = 'This string looks like it should be marked as translatable via __(...).'.freeze

        def on_str(node)
          # Constants like __FILE__ are handled as strings, but don't respond to begin.
          return if !node.loc.respond_to?(:begin) || !node.loc.begin
          return if part_of_ignored_node?(node)

          return if !offense?(node)

          add_offense(node) do |corrector|
            corrector.replace(node, "__(#{node.source})")
          end
        end

        def on_regexp(node)
          ignore_node(node)
        end

        METHOD_NAME_BLOCKLIST = %i[
          __ translate
          include? eql? parse
          debug info warn error fatal unknown log log_error
          field argument description value has_one belongs_to
        ].freeze

        def on_send(node)
          ignore_node(node) if METHOD_NAME_BLOCKLIST.include? node.method_name
        end

        private

        PARENT_SOURCE_BLOCKLIST = [
          # Ignore logged strings
          'Rails.logger'
        ].freeze

        NODE_START_BLOCKLIST = [
          # Only look at strings starting with upper case letters
          %r{[^A-Z]},
          # Ignore strings starting with three upper case letters like SELECT, POST etc.
          %r{[A-Z]{3}},
        ].freeze

        NODE_CONTAIN_BLOCKLIST = [
          # Ignore strings with interpolation.
          '#{',
          # Ignore Email addresses
          '@'
        ].freeze

        def offense?(node) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

          # Ignore Hash Keys
          return false if node.parent.type.eql?(:pair) && node.parent.children.first.equal?(node)

          # Ignore equality checks like ... == 'My String'
          return false if node.left_sibling.eql?(:==)

          # Remove quotes
          node_source = node.source[1..-2]

          # Only match strings with at least two words
          return false if node_source.split.count < 2

          NODE_START_BLOCKLIST.each do |entry|
            return false if node_source.start_with? entry
          end

          NODE_CONTAIN_BLOCKLIST.each do |entry|
            return false if node_source.include? entry
          end

          parent_source = node.parent.source
          PARENT_SOURCE_BLOCKLIST.each do |entry|
            return false if parent_source.include? entry
          end

          true
        end
      end
    end
  end
end
