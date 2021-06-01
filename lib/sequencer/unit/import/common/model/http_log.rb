# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          class HttpLog < Sequencer::Unit::Base

            uses :dry_run, :action, :remote_id, :mapped, :exception

            def process
              return if dry_run

              ::HttpLog.create(
                direction:     'out',
                facility:      facility,
                method:        'tcp',
                url:           "#{action} -> #{remote_id}",
                status:        status,
                ip:            nil,
                request:       {
                  content: mapped,
                },
                response:      {
                  message: response
                },
                created_by_id: 1,
                updated_by_id: 1,
              )
            end

            private

            def status
              @status ||= begin
                action == :failed ? :failed : :success
              end
            end

            def response
              exception ? exception.message : status
            end

            def facility
              raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
            end
          end
        end
      end
    end
  end
end
