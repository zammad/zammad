# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module Ticket
          class TimeEntries < Sequencer::Unit::Import::Freshdesk::SubSequence::Generic
            prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

            optional :action

            skip_action :skipped, :failed

            uses :resource

            def object
              'TimeEntry'
            end

            def sequence_name
              'Sequencer::Sequence::Import::Freshdesk::TimeEntries'.freeze
            end

            def request_params
              super.merge(
                ticket: resource,
              )
            end
          end
        end
      end
    end
  end
end
