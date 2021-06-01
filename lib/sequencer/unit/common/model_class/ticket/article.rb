# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Common
      module ModelClass
        class Ticket < Sequencer::Unit::Common::ModelClass::Base
          class Article < Sequencer::Unit::Common::ModelClass::Base
          end
        end
      end
    end
  end
end
