# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module FormMatchers
  module HaveValidationMessage
    extend RSpec::Matchers::DSL

    matcher :have_validation_message_for do |field|

      match { check_field(field) && form_field_found? && validation_message_found? }
      description { 'have a non empty validation message' }

      failure_message do
        if form_field_found? && !validation_message_found?
          %(expected to find the field '#{field}' with a validation message, found #{field} with no validation message)
        else
          %(expected to find the field '#{field}' with a validation message)
        end
      end

      failure_message_when_negated do
        if form_field_found? && validation_message_found?
          %(expected not to find the field '#{field}' with a validation message, but did)
        else
          %(expected not to find a validation message)
        end
      end

      def validation_message_found?
        actual
        .find(field)
        .native
        .attribute('validationMessage')
        .present?
      end

      def form_field_found?
        actual.has_css?(field)
      end

      def field
        @check_field
      end

      def check_field(field)
        @check_field ||= field
      end
    end
  end
end

RSpec.configure do |config|
  config.include FormMatchers::HaveValidationMessage, type: :system
end
