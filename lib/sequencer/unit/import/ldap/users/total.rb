# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'sequencer/unit/import/common/model/statistics/mixin/empty_diff'

class Sequencer
  class Unit
    module Import
      module Ldap
        module Users
          class Total < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::EmptyDiff

            uses :ldap_config, :ldap_connection, :dry_run

            def process
              state.provide(:statistics_diff) do
                diff.merge(
                  total: total
                )
              end
            end

            private

            def total
              if !dry_run
                result = Cache.read(cache_key)
              end

              result ||= ldap_connection.count(ldap_config[:user_filter])

              if !dry_run
                Cache.write(cache_key, result, { expires_in: 1.hour })
              end

              result
            end

            def cache_key
              @cache_key ||= "#{ldap_connection.host}::#{ldap_connection.port}::#{ldap_connection.ssl}::#{ldap_connection.base_dn}::#{ldap_config[:user_filter]}"
            end
          end
        end
      end
    end
  end
end
