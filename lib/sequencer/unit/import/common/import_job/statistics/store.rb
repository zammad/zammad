# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module ImportJob
          module Statistics
            class Store < Sequencer::Unit::Base

              uses :import_job, :statistics

              def process
                # update the attribute temporarily so we can update it when:
                # - the last update is more than 10 seconds in the past
                # - all instances are processed but the last statistics entry is not written here.
                #    This will be done in the calling Unit of the executed sub sequence
                import_job.result = statistics

                return if !store?

                import_job.save!
              end

              private

              def store?
                return true if import_job.updated_at.blank?

                next_update_at < Time.zone.now
              end

              def next_update_at
                # update every 10 seconds to reduce DB load
                import_job.updated_at + 10.seconds
              end
            end
          end
        end
      end
    end
  end
end
