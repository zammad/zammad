class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          class Mapping < Sequencer::Unit::Import::Common::Mapping::FlatKeys
            uses :ldap_config

            private

            def mapping
              ldap_config[:user_attributes].dup.tap do |config|
                # fallback to uid as login
                # if no login is given via mapping
                if !config.values.include?('login')
                  config[ ldap_config[:user_uid] ] = 'login'
                end
              end
            end
          end
        end
      end
    end
  end
end
