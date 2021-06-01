# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    module HistoryFactory
      extend Import::Factory
      extend self

      def skip?(record, *_args)
        return true if !determine_class(record)

        false
      end

      def backend_class(record, *_args)
        "Import::OTRS::History::#{determine_class(record)}".constantize
      end

      private

      def determine_class(history)
        check_supported(history) || check_article(history)
      end

      def supported_types
        %w[NewTicket StateUpdate Move PriorityUpdate]
      end

      def check_supported(history)
        return if supported_types.exclude?(history['HistoryType'])

        history['HistoryType']
      end

      def check_article(history)
        return if !history['ArticleID']
        return if history['ArticleID'].to_i.zero?

        'Article'
      end
    end
  end
end
