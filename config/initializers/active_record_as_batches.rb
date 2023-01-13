# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# https://github.com/telent/ar-as-batches
# TODO: Should be reconsidered with rails 6.1 because then
# find_each might be able to handle order as well
# e.g. Ticket::Priority.order(updated: :desc).find_each... is not possbile atm with find_each
module ActiveRecord
  module AsBatches
    class Batch
      def initialize(arel, args)
        @offset = arel.offset || 0
        @limit  = arel.limit
        @size   = args[:size] || 100
        return if !@limit || (@limit > @size)

        @size = @limit
      end

      def get_records(query)
        query.offset(@offset).limit(@size).all
      end

      def as_batches(query, &)
        records = get_records(query)
        while records.any?
          @offset += records.size
          records.each(&)

          if @limit
            @limit -= records.size
            if @limit < size
              @size = @limit
            end

            return if @limit.zero?
          end

          records = get_records(query)
        end
      end
    end

    def as_batches(args = {}, &)
      Batch.new(arel, args).as_batches(self, &)
    end
  end

  class Relation
    include AsBatches
  end
end
