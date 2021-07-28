# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module SubSequence
          class Generic < Sequencer::Unit::Base

            uses :dry_run, :import_job, :field_map, :id_map

            attr_accessor :iteration

            def process
              loop.each_with_index do |_, iteration|
                @iteration = iteration

                result = ::Sequencer.process(sequence_name,
                                             parameters: {
                                               request_params: request_params,
                                               import_job:     import_job,
                                               dry_run:        dry_run,
                                               object:         object,
                                               field_map:      field_map,
                                               id_map:         id_map,
                                             },
                                             expecting:  %i[action response])
                break if iteration_should_stop?(result)
              end
            end

            def request_params
              {
                page: page,
              }
            end

            def page
              iteration + 1
            end

            def object
              @object ||= self.class.name.demodulize.singularize
            end

            def sequence_name
              raise NotImplementedError
            end

            private

            def iteration_should_stop?(result)
              return true if result[:action] == :failed
              return true if result[:response].header['link'].blank?

              max_page_reached?
            end

            # https://github.com/zammad/zammad/issues/3661
            # https://developers.freshdesk.com/api/#list_all_tickets
            def max_page_reached?
              return false if object != 'Ticket'
              return false if page <= 300

              logger.warn "Reached max Freshdesk API page number #{page} for #{object}. Stopping further requests to prevent errors."
              true
            end
          end
        end
      end
    end
  end
end
