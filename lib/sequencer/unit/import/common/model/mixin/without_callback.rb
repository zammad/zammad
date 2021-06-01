# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Mixin
            module WithoutCallback
              module ClassMethods

                def without_callback(*callback)
                  @callbacks ||= []
                  @callbacks.push(callback)
                end

                def callbacks
                  Array(@callbacks)
                end
              end

              def self.prepended(base)
                base.extend(ClassMethods)
                base.uses :model_class
              end

              def process
                # keep the super call as the last or only entry point
                entry_point = proc do
                  super
                end

                # loop over all registerd callbacks
                self.class.callbacks.each do |callback|

                  # create a duplicate of the previous entry point
                  # to avoid an endless loop
                  previous_entry_point = entry_point.dup

                  # replace the previous entry point with a wrapped version
                  # which skips the current callback
                  entry_point = proc do
                    model_class.without_callback(*callback, &previous_entry_point)
                  end
                end

                # start at the last registerd entry point
                # and go deep till we reach our super call
                entry_point.call
              end
            end
          end
        end
      end
    end
  end
end
