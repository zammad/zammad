# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ExternalDataSource
  module Errors
    class BaseError < StandardError
      attr_reader :external_data_source

      def initialize(external_data_source)
        @external_data_source = external_data_source
        super
      end

      def log_message(attribute_display, custom_message: nil)
        format(__('Cannot process external data source %s. %s'), attribute_display, custom_message || message)
      end
    end

    class NetworkError < BaseError
      def initialize(external_data_source, message)
        @message = message

        super(external_data_source)
      end

      attr_reader :message

      def log_message(attribute_display)
        super(attribute_display, custom_message: __('See HTTPLog for details.'))
      end
    end

    class SearchUrlMissingError < BaseError
      def message
        __('Search URL is missing.')
      end
    end

    class SearchUrlInvalidError < BaseError
      def message
        __('Search URL is invalid.')
      end
    end

    class ParsingError < BaseError
      attr_reader :parsing_path

      def initialize(external_data_source, path)
        @parsing_path = path

        super(external_data_source)
      end

      def self.class_for(type, location)
        case [type, location]
        in [:value, :path]
          ItemValuePathParsingError
        in [:value, :invalid]
          ItemValueInvalidTypeParsingError
        in [:label, :path]
          ItemLabelPathParsingError
        in [:label, :invalid]
          ItemLabelInvalidTypeParsingError
        end
      end
    end

    class ListPathParsingError < ParsingError
      def message
        format(__('Search result list key "%s" was not found.'), parsing_path)
      end
    end

    class ListNotArrayParsingError < ParsingError
      def message
        if parsing_path.blank?
          return format(__('Search result list is not an array. Please provide search result list key.'))
        end

        format(__('Search result list key "%s" is not an array.'), parsing_path)
      end
    end

    class ItemValuePathParsingError < ParsingError
      def message
        format(__('Search result value key "%s" was not found.'), parsing_path)
      end
    end

    class ItemValueInvalidTypeParsingError < ParsingError
      def message
        if parsing_path.blank?
          return format(__('Search result value is not a string, a number or a boolean. Please provide search result value key.'))
        end

        format(__('Search result value key "%s" is not a string, number or boolean.'), parsing_path)
      end
    end

    class ItemLabelPathParsingError < ParsingError
      def message
        format(__('Search result label key "%s" was not found.'), parsing_path)
      end
    end

    class ItemLabelInvalidTypeParsingError < ParsingError
      def message
        if parsing_path.blank?
          return format(__('Search result label is not a string, a number or a boolean. Please provide search result label key.'))
        end

        format(__('Search result label key "%s" is not a string, number or boolean.'), parsing_path)
      end
    end
  end
end
