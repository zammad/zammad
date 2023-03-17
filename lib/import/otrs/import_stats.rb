# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Import
  module OTRS
    module ImportStats
      extend self

      def current_state
        {
          Base:   {
            done:  base_done,
            total: base_total,
          },
          User:   {
            done:  user_done,
            total: user_total,
          },
          Ticket: {
            done:  ticket_done,
            total: ticket_total,
          },
        }
      end

      def statistic

        # check cache
        cache = Rails.cache.read('import_otrs_stats')
        return cache if cache

        # retrieve statistic
        statistic = Import::OTRS::Requester.list
        return statistic if !statistic

        Rails.cache.write('import_otrs_stats', statistic)
        statistic
      end

      private

      def base_done
        ::Group.count + ::Ticket::State.count + ::Ticket::Priority.count
      end

      def base_total
        sum_stat(%w[Queue State Priority])
      end

      def user_done
        ::User.count
      end

      def user_total
        sum_stat(%w[User CustomerUser])
      end

      def ticket_done
        ::Ticket.count
      end

      def ticket_total
        sum_stat(%w[Ticket])
      end

      def sum_stat(objects)
        data = statistic
        sum  = 0
        objects.each do |object|
          sum += data[object]
        end
        sum
      end
    end
  end
end
