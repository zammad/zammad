# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'sequencer/unit/import/common/sub_sequence/mixin/import_job'

class Sequencer
  class Unit
    module Import
      module Ldap
        module Users
          class SubSequence < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::SubSequence::Mixin::ImportJob

            uses :ldap_config, :ldap_connection, :dn_roles, :model_class, :external_sync_source
            provides :found_ids

            def process
              ldap_connection.search(ldap_config[:user_filter], attributes: relevant_attributes) do |entry|

                result = sequence_resource(entry)

                next if result[:instance].blank?

                found_ids.push(result[:instance].id)
              end

              state.provide(:found_ids, found_ids)
            end

            private

            def found_ids
              @found_ids ||= []
            end

            def default_params
              super.merge(
                dn_roles:             dn_roles,
                ldap_config:          ldap_config,
                model_class:          model_class,
                external_sync_source: external_sync_source,
                signup_role_ids:      signup_role_ids,
                found_ids:            found_ids,
              )
            end

            def signup_role_ids
              @signup_role_ids ||= Role.signup_role_ids.sort
            end

            def sequence
              'Import::Ldap::User'
            end

            def relevant_attributes
              # limit the fetched attributes for an entry to only
              # those which are needed to improve the performance
              attributes = ldap_config[:user_attributes].keys
              attributes.push('dn')
              attributes.push(ldap_config[:user_uid])
              attributes.uniq
            end
          end
        end
      end
    end
  end
end
