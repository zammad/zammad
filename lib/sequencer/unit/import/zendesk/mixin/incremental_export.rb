# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Mixin
          module IncrementalExport

            attr_accessor :previous_page

            def self.included(base)
              base.uses :client
              base.provides :import_job
            end

            def resource_collection
              @resource_collection ||= "::ZendeskAPI::#{resource_klass}".constantize.incremental_export(client, 1)
            end

            def resource_iteration
              super do |record|
                # call passed/originally intended block
                yield(record)

                # add hook to check if object (e.g. ticket) count
                # update is needed because the request
                # might have changed
                update_count
              end
            end

            # The source if this is the limitation of not knowing
            # how much objects there are in total before requesting the endpoint
            # This is caused by the Zendesk API which only returns max. 1000
            # per request
            def update_count
              update_import_job

              self.previous_page = current_page
            end

            def update_import_job
              return if !update_required?

              state.provide(:import_job, updated_import_job)
            end

            def klass_key
              @klass_key ||= resource_klass.pluralize.to_sym
            end

            def updated_import_job
              import_job.result[klass_key][:total] += current_request_count
              import_job
            end

            def update_required?
              # means: still on first page
              return false if current_page.blank?

              previous_page != current_page
            end

            def current_request_count
              # access the internal instance method of the
              # Zendesk collection request to get the current
              # count of the fetched result (max. 1000)
              resource_collection.fetch.size
            end

            def current_page
              # access the internal instance method of the
              # Zendesk collection request to get the current
              # page number of the endpoint
              resource_collection.instance_variable_get(:@query)
            end
          end
        end
      end
    end
  end
end
