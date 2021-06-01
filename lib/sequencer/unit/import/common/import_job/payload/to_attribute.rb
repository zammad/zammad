# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module ImportJob
          module Payload
            class ToAttribute < Sequencer::Unit::Base

              uses :import_job

              def process
                provides = self.class.provides
                raise "Can't find any provides for #{self.class.name}" if provides.blank?

                provides.each do |attribute|
                  state.provide(attribute, import_job.payload[attribute])
                end
              end
            end
          end
        end
      end
    end
  end
end
