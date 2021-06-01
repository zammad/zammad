# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module KnowledgeBasePublicMatchers
  module HaveBreadcrumb
    extend RSpec::Matchers::DSL

    matcher :have_breadcrumb do
      match { breadcrumb_found? && of_specified_length? }

      chain(:with, :length)
      chain(:items) { nil }

      description do
        if @length.present?
          "have #{@length}-item breadcrumb"
        else
          'have breadcrumb'
        end
      end

      failure_message do
        if breadcrumb_found? && !of_specified_length?
          "expected breadcrumb to contain #{@length} items (#{actual_length} found)"
        else
          'expected to find breadcrumb, but none was found'
        end
      end

      failure_message_when_negated do
        if breadcrumb_found? && @length.present?
          "expected breadcrumb not to contain #{@length} items"
        else
          'expected not to find breadcrumb, but did'
        end
      end

      def breadcrumb_found?
        actual.has_css?('.breadcrumbs')
      end

      def of_specified_length?
        @length.nil? || @length == actual_length
      end

      def actual_length
        actual.all('.breadcrumbs .breadcrumb').length
      end
    end
  end
end

RSpec.configure do |config|
  config.include KnowledgeBasePublicMatchers::HaveBreadcrumb, type: :system
end
