# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Common
      module ModelClass
        class Base < Sequencer::Unit::Common::Provider::Attribute

          provides :model_class

          private

          def model_class
            @model_class ||= class_name.constantize
          end

          def class_name
            self.class.name.sub('Sequencer::Unit::Common::ModelClass', '')
          end
        end
      end
    end
  end
end
