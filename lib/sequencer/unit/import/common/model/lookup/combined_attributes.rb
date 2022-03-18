# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Lookup
            class CombinedAttributes < Sequencer::Unit::Import::Common::Model::Lookup::Attributes
              def existing_instance
                @existing_instance ||= begin
                  filters = {}

                  Array(attributes).each do |attribute|
                    value = mapped[attribute]
                    next if value.blank?

                    filters[attribute] = value
                  end

                  if filters.present?
                    model_class.find_by(filters)
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
