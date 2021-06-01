# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
          loop do
            result = {
              data:   current_state,
              result: 'in_progress',
            }
            Cache.write('import:state', result, expires_in: 10.minutes)
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
          Cache.write('import:state', result, expires_in: 10.hours)
          return false
        end
        sleep 16 # wait until new finished import state is on client
        status_update_thread.exit
        status_update_thread.join

        result = {
          result: 'import_done',
        }
        Cache.write('import:state', result, expires_in: 10.hours)

        Setting.set('system_init_done', true)
        Setting.set('import_mode', false)
      end

      def status_bg
        state = Cache.read('import:state')
        return state if state

        {
          message: 'not running',
        }
      end
    end
  end
end
