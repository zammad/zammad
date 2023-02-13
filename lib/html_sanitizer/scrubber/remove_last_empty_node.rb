# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  module Scrubber
    class RemoveLastEmptyNode < Base
      attr_reader :remove_empty_nodes, :remove_empty_last_nodes

      def initialize # rubocop:disable Lint/MissingSuper
        @direction = :bottom_up

        @remove_empty_nodes      = %w[p div span small table]
        @remove_empty_last_nodes = %w[b i u small table]
      end

      def scrub(node)
        return scrub_children(node) if node.children.present?

        return if remove_empty_nodes.exclude?(node.name) && remove_empty_last_nodes.exclude?(node.name)
        return if node.content.present?
        return if node.attributes.present?

        node.remove
        STOP
      end

      private

      def scrub_children(node)
        return  if !node.children.one?

        if matching_element_with_attributes?(node)
          replace_parent_with_attributes(node)
        elsif matching_element_sans_attributes?(node)
          replace_parent_sans_attributes(node)
        end
      end

      def matching_element_with_attributes?(node)
        return if node.name != node.children.first.name
        return if node.attributes.blank?
        return if node.children.first.attributes.present?

        true
      end

      def replace_parent_with_attributes(node)
        local_node_child = node.children.first
        node.attributes.each do |key, value|
          local_node_child.set_attribute(key, value)
        end
        node.replace local_node_child.to_s

        STOP
      end

      def matching_element_sans_attributes?(node)
        return if node.name != 'span' && node.name != node.children.first.name
        return if node.attributes.present?

        true
      end

      def replace_parent_sans_attributes(node)
        node.replace node.children.to_s

        STOP
      end
    end
  end
end
