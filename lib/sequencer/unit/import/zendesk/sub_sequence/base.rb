# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module SubSequence
          module Base
            module ClassMethods

              def resource_klass
                @resource_klass ||= name.split('::').last.singularize
              end
            end

            def self.included(base)
              base.extend(ClassMethods)

              base.uses :dry_run, :import_job
            end

            private

            def default_params
              {
                dry_run:    dry_run,
                import_job: import_job,
              }
            end

            def resource_klass
              # base.instance_delegate [:resource_klass] => base
              # doesn't work since we are included and then inherited
              # there might be multiple inherited hooks which overwrite
              # each other :/
              self.class.resource_klass
            end

            def sequence_name
              "Import::Zendesk::#{resource_klass}"
            end

            def resource_iteration(&block)
              resource_collection.public_send(resource_iteration_method, &block)
            rescue ZendeskAPI::Error::NetworkError => e
              return if expected_exception?(e)
              raise if !retry_exception?(e)
              raise if (fail_count ||= 1) > 10

              logger.error e
              logger.info "Sleeping 10 seconds after ZendeskAPI::Error::NetworkError and retry (##{fail_count}/10)."
              sleep 10

              fail_count += 1
              retry
            end

            # #2262 Zendesk-Import fails for User & Organizations when 403 "access" denied
            def expected_exception?(e)
              status = e.response.status.to_s
              return false if status != '403'

              %w[UserField OrganizationField].include?(resource_klass)
            end

            def retry_exception?(e)
              return true if e.message.include?('execution expired')

              status = e.response.status.to_s
              status.match?(%r{^(4|5)\d\d$})
            end

            def resource_collection
              @resource_collection ||= collection_provider.public_send(resource_collection_attribute)
            end

            def resource_iteration_method
              :all!
            end

            def resource_collection_attribute
              @resource_collection_attribute ||= resource_klass.pluralize.underscore
            end
          end
        end
      end
    end
  end
end
