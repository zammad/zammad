# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Common
      module ModelClass
        class Ticket < Sequencer::Unit::Common::ModelClass::Base
          class TimeAccounting < Sequencer::Unit::Common::ModelClass::Base
          end
        end
      end
    end
  end
end
