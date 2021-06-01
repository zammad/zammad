# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module FindBy
            class SameNamedAttribute < Sequencer::Unit::Import::Common::Model::Lookup::Attributes

              private

              def attribute
                self.class.name.demodulize.underscore.to_sym
              end
            end
          end
        end
      end
    end
  end
end
