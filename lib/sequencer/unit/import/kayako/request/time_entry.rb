# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Request < Sequencer::Unit::Common::Provider::Attribute
  class TimeEntry < Sequencer::Unit::Import::Kayako::Request::Generic
    def api_path
      'timetracking'
    end
  end
end
