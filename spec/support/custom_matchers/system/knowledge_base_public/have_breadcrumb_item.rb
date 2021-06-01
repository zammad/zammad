# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module KnowledgeBasePublicMatchers
  module HaveBreadcrumbItem
    extend RSpec::Matchers::DSL

    matcher :have_breadcrumb_item do |expected|
      match { breadcrumb_item_found? && at_specified_index? }

      chain(:at_index, :index)

      description do
        if @index.present?
          %(have "#{expected}" in breadcrumb at index #{@index})
        else
          %(have "#{expected}" in breadcrumb)
        end
      end

      failure_message do
        if breadcrumb_item_found? && !at_specified_index?
          %(expected to find "#{expected}" at index #{@index} of breadcrumb (found at #{breadcrumb_item_index}))
        else
          %(expected to find "#{expected}" in breadcrumb, but did not)
        end
      end

      failure_message_when_negated do
        if breadcrumb_item_found? && @index.present?
          %(expected not to find "#{expected}" at index #{@index} of breadcrumb)
        else
          %(expected not to find "#{expected}" in breadcrumb, but did)
        end
      end

      def breadcrumb_item_found?
        !breadcrumb_item_index.nil?
      end

      def at_specified_index?
        @index.nil? || @index == breadcrumb_item_index
      end

      def breadcrumb_item_index
        @breadcrumb_item_index ||= actual.all('.breadcrumbs .breadcrumb').index do |item|
          item.find('span').text == expected
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include KnowledgeBasePublicMatchers::HaveBreadcrumbItem, type: :system
end
