# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          module Lookup
            class Attributes < Sequencer::Unit::Import::Common::Model::FindBy::UserAttributes

              uses :found_ids, :external_sync_source

              private

              def lookup(attribute:, value:)
                entries = model_class.where(attribute => value).to_a
                return if entries.blank?

                not_synced(entries)
              end

              def not_synced(entries)
                entries.find { |entry| not_synced?(entry) }
              end

              def not_synced?(entry)
                found_ids.exclude?(entry.id)
              end
            end
          end
        end
      end
    end
  end
end
