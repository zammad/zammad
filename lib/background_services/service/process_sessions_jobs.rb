# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class Service
    class ProcessSessionsJobs < Service
      attr_reader :client_threads

      def self.max_workers
        16
      end

      def self.pre_run
        previous_nodes_sessions = Sessions::Node.stats
        return if previous_nodes_sessions.blank?

        Rails.logger.info { "Cleaning up previous Sessions::Node sessions: #{previous_nodes_sessions}" }
        Sessions::Node.cleanup
      end

      def initialize(...)
        @client_threads = Concurrent::Hash.new
        super
      end

      def launch
        loop do
          break if BackgroundServices.shutdown_requested

          ActiveRecord::Base.clear_query_caches_for_current_thread

          start_threads_for_new_client_sessions

          sleep 1
        end

        client_threads.values.compact.each(&:join)
      end

      private

      def fetch_client_ids
        return Sessions.sessions if !fork_id

        Sessions::Node.register(fork_id)
        Sessions::Node.sessions_by(fork_id)
      end

      def start_threads_for_new_client_sessions
        fetch_client_ids.each do |client_id|
          # connection already open, ignore
          next if client_threads[client_id]

          # check current user
          next if !valid_client_session?(client_id)

          start_client_session_thread(client_id)

          sleep 1
        end
      end

      def valid_client_session?(client_id)
        session_user_id = Sessions.get(client_id)&.dig(:user, 'id')

        return false if session_user_id.blank?

        User.exists?(session_user_id)
      end

      def start_client_session_thread(client_id)
        client_threads[client_id] = Thread.new do
          Thread.current.name = "ProcessSessionJobs session client thread (client_id: #{client_id})"

          Rails.application.executor.wrap do
            Sessions.thread_client(client_id, 0, Time.now.utc, fork_id)
            client_threads.delete(client_id)
            Rails.logger.info { "Closing session client (#{client_id}) thread" }
          end
        end
      end
    end
  end
end
