class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Associations
            class Extract < Sequencer::Unit::Base

              uses :model_class, :mapped
              provides :associations

              def process
                state.provide(:associations) do
                  associations.collect do |association|
                    next if !mapped.key?(association)

                    # remove from the mapped values if it's an association
                    value = mapped.delete(association)

                    # skip if we don't track them
                    next if tracked_associations.exclude?(association)

                    [association, value]
                  end.compact.to_h
                end
              end

              private

              def associations
                @associations ||= begin
                  associations = []
                  # loop over all reflections
                  model_class.reflect_on_all_associations.each do |reflection|

                    # refection name is something like groups or organization (singular/plural)
                    associations.push(reflection.name)

                    # key is something like group_id or organization_id (singular)
                    key = reflection.klass.name.foreign_key

                    # add trailing 's' to get pluralized key
                    reflection_name = reflection.name.to_s
                    if reflection_name.singularize == reflection_name
                      key = "#{key}s"
                    end

                    # store _id/_ids name
                    associations.push(key.to_sym)
                  end
                  associations
                end
              end

              def tracked_associations
                # track all associations by default
                associations
              end
            end
          end
        end
      end
    end
  end
end
