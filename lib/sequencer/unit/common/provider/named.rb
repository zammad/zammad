# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Common
      module Provider
        class Named < Sequencer::Unit::Common::Provider::Attribute

          module ClassMethods
            def named_provide
              name.demodulize.underscore.to_sym
            end
          end

          def self.inherited(base)
            super

            base.extend(ClassMethods)
            base.provides(base.named_provide)

            base.extend(Forwardable)
          end

          def provides
            self.class.named_provide
          end
        end
      end
    end
  end
end
