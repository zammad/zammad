module Import
  module Zendesk
    module TicketFactory
      extend Import::Zendesk::BaseFactory

      # rubocop:disable Style/ModuleFunction
      extend self

      private

      def import_loop(records, *args)

        count_update_hook = proc { |record|
          yield(record)
          update_ticket_count(records)
        }

        super(records, *args, &count_update_hook)
      end

      def update_ticket_count(collection)

        cache_key      = 'import_zendesk_stats'
        count_variable = :@count
        page_variable  = :@next_page

        next_page    = collection.instance_variable_get(page_variable)
        @last_page ||= next_page

        return if @last_page == next_page
        return if !collection.instance_variable_get(count_variable)

        @last_page = next_page

        # check cache
        cache = Cache.get(cache_key)
        return if !cache

        cache['Tickets'] ||= 0
        cache['Tickets']  += collection.instance_variable_get(count_variable)

        Cache.write(cache_key, cache)
      end
    end
  end
end
