# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        class Request < Sequencer::Unit::Common::Provider::Attribute
          class TimeEntry < Sequencer::Unit::Import::Freshdesk::Request::Generic
            attr_reader :ticket

            def initialize(*)
              super
              @ticket = request_params.delete(:ticket)
            end

            def api_path
              "tickets/#{ticket['id']}/time_entries"
            end
          end
        end
      end
    end
  end
end
