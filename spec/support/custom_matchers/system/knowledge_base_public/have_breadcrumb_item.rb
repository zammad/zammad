# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module KnowledgeBasePublicMatchers
  module HaveBreadcrumbItem
    extend RSpec::Matchers::DSL

    matcher :have_breadcrumb_item do |expected|
      match { breadcrumb_item_found? && at_specified_index? && with_specified_url? }

      chain(:at_index, :index)
      chain(:with_url, :url)

      description do
        description = %(have "#{expected}" in breadcrumb)

        if @index.present?
          description += %( at index #{@index})
        end

        if @url.present?
          description += %( with urlx #{@url})
        end

        description
      end

      failure_message do
        if breadcrumb_item_found? && !at_specified_index?
          %(expected to find "#{expected}" at index #{@index} of breadcrumb (found at #{breadcrumb_item_index}))
        elsif breadcrumb_item_found? && !with_specified_url?
          %(expected to find "#{expected}" with url #{@url} (found with #{breadcrumb_item_url}))
        else
          %(expected to find "#{expected}" in breadcrumb, but did not)
        end
      end

      failure_message_when_negated do
        if breadcrumb_item_found? && @url.present? && @index.present?
          %(expected not to find "#{expected}" with url #{@url} at index #{@index} of breadcrumb)
        elsif breadcrumb_item_found? && @index.present?
          %(expected not to find "#{expected}" at index #{@index} of breadcrumb)
        elsif breadcrumb_item_found? && @url.present?
          %(expected not to find "#{expected}" with url #{@url})
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

      def with_specified_url?
        @url.nil? || @url == breadcrumb_item_url
      end

      def breadcrumb_item_index
        @breadcrumb_item_index ||= actual.all('.breadcrumbs .breadcrumb').index do |item|
          item.find('span').text == expected
        end
      end

      def breadcrumb_item_url
        @breadcrumb_item_url ||= begin
          elem = actual
            .all('.breadcrumbs .breadcrumb')
            .find do |item|
              item.find('span').text == expected
            end

          elem ? elem[:href] : nil
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include KnowledgeBasePublicMatchers::HaveBreadcrumbItem, type: :system
end
