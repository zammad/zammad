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
                                             expecting:  [:response])
                break if result[:response].header['link'].blank?
              end
            end

            def request_params
              {
                page: iteration + 1,
              }
            end

            def object
              self.class.name.demodulize.singularize
            end

            def sequence_name
              raise NotImplementedError
            end
          end
        end
      end
    end
  end
end
