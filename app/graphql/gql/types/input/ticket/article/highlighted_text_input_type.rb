# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class Article::HighlightedTextInputType < Gql::Types::BaseInputObject
    description 'Input fields for ticket article highlighted text information.'

    argument :start_index, Integer, required: true, description: 'Start index of the highlighted text'
    argument :end_index, Integer, required: true, description: 'End index of the highlighted text'
    argument :color_class, String, required: true, description: 'Color of the highlighted text'

    transform :transform_color_class

    def transform_color_class(payload)
      payload.to_h.tap do |result|
        result[:color_class] = transform_color_class_value(result[:color_class])
      end
    end

    private

    def transform_color_class_value(value)
      return value if value.exclude?('-')

      value.split('-').then { |parts| "#{parts[0..-2].join('-')}-#{parts[-1].capitalize}" }
    end
  end
end
