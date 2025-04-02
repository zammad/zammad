# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class Service
    class ManageSessionsJobs < Service
      def self.max_workers
        1
      end

      # This service is only needed when we have forked ProcessSessionJobs running,
      #   to coordinate the sessions between the different processes.
      def self.skip?(manager:)
        session_jobs_config = manager.config.find { |elem| elem.service == BackgroundServices::Service::ProcessSessionsJobs }

        !session_jobs_config || session_jobs_config.disabled || session_jobs_config.start_as != :fork
      end

      def launch
        loop do
          break if BackgroundServices.shutdown_requested

          single_run

          sleep 1
        end
      end

      private

      def single_run
        nodes_stats = Sessions::Node.stats

        Sessions
          .sessions
          .each do |client_id|
            # ask nodes for nodes
            next if nodes_stats[client_id]

            # assign to node
            Sessions::Node.session_assigne(client_id)
            sleep 1
          end
      end
    end
  end
end
