# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Common
      module Mixin
        module DynamicAttribute

          def self.included(base)

            class << base

              def inherited(base)
                super

                base.extend(Forwardable)
                base.instance_delegate [:attribute] => base
              end

              def attribute
                @attribute ||= begin
                  if uses.size != 1
                    raise "DynamicAttribute classes can use exactly one attribute. Found #{uses.size}."
                  end

                  uses.first
                end
              end
            end
          end

          private

          def attribute_value
            @attribute_value ||= state.use(attribute)
          end
        end
      end
    end
  end
end
