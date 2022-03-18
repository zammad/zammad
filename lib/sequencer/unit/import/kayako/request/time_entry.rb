# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        class Request < Sequencer::Unit::Common::Provider::Attribute
          class TimeEntry < Sequencer::Unit::Import::Kayako::Request::Generic
            def api_path
              'timetracking'
            end
          end
        end
      end
    end
  end
end
