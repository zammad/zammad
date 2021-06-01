# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Rails autoload has some issues with same namend sub-classes
# in the importer folder require AND simultaniuos requiring
# of the same file in different threads so we need to
# require them ourself
require_dependency 'import/otrs/ticket'
require_dependency 'import/otrs/ticket_factory'
require_dependency 'import/otrs/article_customer'
require_dependency 'import/otrs/article_customer_factory'
require_dependency 'import/otrs/article'
require_dependency 'import/otrs/article_factory'
require_dependency 'import/otrs/article/attachment_factory'
require_dependency 'import/otrs/history'
require_dependency 'import/otrs/history_factory'
require_dependency 'import/otrs/history/article'
require_dependency 'import/otrs/history/move'
require_dependency 'import/otrs/history/new_ticket'
require_dependency 'import/otrs/history/priority_update'
require_dependency 'import/otrs/history/state_update'
require_dependency 'store'
require_dependency 'store/object'
require_dependency 'store/provider/db'
require_dependency 'store/provider/file'

module Import
  module OTRS
    extend Import::Helper
    extend Import::OTRS::ImportStats
    extend Import::OTRS::Async
    extend Import::OTRS::Diff
    extend self

    # Start import with specific parameters.
    # Useful for debug and continuing from breakpoint of last not success import
    #
    # @example
    #   Import::OTRS::start() - Nomrmal usage
    #
    #   Import::OTRS::start(thread: 1, offset: 1000) - Run the task in Single-Thread and start from offset 1000

    def start(args = {})
      log 'Start import...'

      checks

      prerequisites

      base_objects

      updateable_objects

      customer_user

      threaded_import('Ticket', args)

      true
    end

    def connection_test
      Import::OTRS::Requester.connection_test
    end

    private

    def checks
      check_import_mode
      check_system_init_done
      connection_test
    end

    def prerequisites
      # make sure to create store type otherwise
      # it might lead to race conditions while
      # creating it in different import threads
      Store::Object.create_if_not_exists(name: 'Ticket::Article')
    end

    def import(remote_object, args = {})
      log "loading #{remote_object}..."
      import_action(remote_object, args)
    end

    def threaded_import(remote_object, args = {})
      thread_count      = args[:threads] || 8
      limit             = args[:limit]   || 20
      start_offset_base = args[:offset]  || 0

      Thread.abort_on_exception = true
      threads                   = {}
      (1..thread_count).each do |thread|

        threads[thread] = Thread.new do

          # In some environments the Model.reset_column_information
          # is not reflected to threads. So an import error message appears.
          # Reset needed model column information for each thread.
          reset_database_information

          Thread.current[:thread_no]  = thread
          Thread.current[:loop_count] = 0

          log "Importing #{remote_object} in steps of #{limit}"
          loop do
            # get the offset for the current thread and loop count
            thread_offset_base = (Thread.current[:thread_no] - 1) * limit
            thread_step        = thread_count * limit
            offset             = Thread.current[:loop_count] * thread_step + thread_offset_base + start_offset_base

            break if !imported?(
              remote_object: remote_object,
              limit:         limit,
              offset:        offset,
              diff:          args[:diff]
            )

            Thread.current[:loop_count] += 1
          end
          ActiveRecord::Base.connection.close
        end
      end
      (1..thread_count).each do |thread| # rubocop:disable Style/CombinableLoops
        threads[thread].join
      end
    end

    def limit_import(remote_object, args = {})
      offset = 0
      limit  = args[:limit] || 20
      log "Importing #{remote_object} in steps of #{limit}"
      loop do

        break if !imported?(
          remote_object: remote_object,
          limit:         limit,
          offset:        offset,
          diff:          args[:diff]
        )

        offset += limit
      end
    end

    def imported?(args)
      log "loading #{args[:limit]} #{args[:remote_object]} starting at #{args[:offset]}..."
      return false if !import_action(args[:remote_object], limit: args[:limit], offset: args[:offset], diff: args[:diff])

      true
    end

    def import_action(remote_object, args = {})
      records = Import::OTRS::Requester.load(remote_object, limit: args[:limit], offset: args[:offset], diff: args[:diff])
      if records.blank?
        log '... no more work.'
        return false
      end
      factory_class(remote_object).import(records)
    end

    def factory_class(object)
      "Import::OTRS::#{object}Factory".constantize
    end

    # sync settings
    def base_objects
      import('SysConfig')
      import('DynamicField')
    end

    def updateable_objects
      import('State')
      import('Priority')
      import('Queue')
      import('User')
      import('Customer')
    end

    def customer_user
      limit_import('CustomerUser', limit: 50)
    end

    def reset_database_information
      ::Ticket.reset_column_information
    end
  end
end
