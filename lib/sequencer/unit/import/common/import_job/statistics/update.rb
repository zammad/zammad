# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module ImportJob
          module Statistics
            class Update < Sequencer::Unit::Base

              uses     :statistics_diff
              optional :import_job
              provides :statistics

              def process
                state.provide(:statistics) do
                  sum_deeply(
                    existing:  statistics,
                    additions: statistics_diff
                  )
                end

                # reset diff to avoid situations where old diff gets added multiple times
                state.unset(:statistics_diff)
              end

              private

              def statistics
                return {} if import_job.nil?

                import_job.result
              end

              def sum_deeply(existing:, additions:)
                existing.merge(additions) do |_key, oldval, newval|
                  if oldval.is_a?(Hash) || newval.is_a?(Hash)
                    sum_deeply(
                      existing:  oldval,
                      additions: newval
                    )
                  else
                    oldval + newval
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
