# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Import
  module OTRS
    module Async
      # rubocop:disable Style/ModuleFunction
      extend self

      def start_bg
        Setting.reload

        Import::OTRS::Requester.connection_test

        # start thread to observe current state
        status_update_thread = Thread.new do
          Thread.current.name = 'OTRS import status update'
          loop do
            result = {
              data:   current_state,
              result: 'in_progress',
            }
            Rails.cache.write('import:state', result, expires_in: 10.minutes)
            sleep 8
          end
        end
        sleep 2

        # start import data
        begin
          Import::OTRS.start
        rescue => e
          status_update_thread.exit
          status_update_thread.join
          Rails.logger.error e
          result = {
            message: e.message,
            result:  'error',
          }
          Rails.cache.write('import:state', result, expires_in: 10.hours)
          return false
        end
        sleep 16 # wait until new finished import state is on client
        status_update_thread.exit
        status_update_thread.join

        result = {
          data:   current_state,
          result: 'import_done',
        }
        Rails.cache.write('import:state', result, expires_in: 10.hours)

        Setting.set('import_mode', false)
        Setting.set('system_init_done', true)
      end

      def status_bg
        state = Rails.cache.read('import:state')
        return state if state

        {
          message: 'not running',
        }
      end
    end
  end
end
