# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        class ImportSettingsUnset < Sequencer::Unit::Base
          def process
            Setting.set('import_kayako_endpoint_username', nil)
            Setting.set('import_kayako_endpoint_password', nil)
          end
        end
      end
    end
  end
end
