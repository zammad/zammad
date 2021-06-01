# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module User
          module Email
            class CheckValidity < Sequencer::Unit::Base
              prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

              skip_action :skipped, :failed

              uses :mapped

              def process
                return if mapped[:email].blank?

                # TODO: This should be done totally somewhere central
                mapped[:email] = ensure_valid_email(mapped[:email])
              end

              private

              def ensure_valid_email(source)
                # TODO: should get unified with User#check_email
                email = extract_email(source)
                return if !email

                email.downcase
              end

              def extract_email(source)
                # Support format like "Bob Smith (bob@example.com)"
                if source =~ %r{\((.+@.+)\)}
                  source = $1
                end

                Mail::Address.new(source).address
              rescue
                return source if source !~ %r{<\s*([^>]+)}

                $1.strip
              end
            end
          end
        end
      end
    end
  end
end
