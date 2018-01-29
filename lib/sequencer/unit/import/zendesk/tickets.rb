class Sequencer
  class Unit
    module Import
      module Zendesk
        class Tickets < Sequencer::Unit::Import::Zendesk::SubSequence::Object

          uses :user_map, :organization_map, :group_map, :ticket_field_map

          private

          def default_params
            super.merge(
              user_map:         user_map,
              group_map:        group_map,
              organization_map: organization_map,
              ticket_field_map: ticket_field_map,
            )
          end

          def resource_iteration
            super do |record|
              # call passed/originally intended block
              yield(record)

              # add hook to check if ticket count
              # update is needed because the request
              # might have changed
              update_ticket_count
            end
          end

          # The source if this is the limitation of not knowing
          # how much tickets there are in total before requesting the endpoint
          # This is caused by the Zendesk API which only returns max. 1000
          # per request
          def update_ticket_count
            update_import_job
            previous_page = next_page
          end

          attr_accessor :previous_page

          def update_import_job
            return if !update_required?
            state.provide(import_job, updated_import_job)
          end

          def updated_import_job
            import_job.result[:Tickets].merge(
              total: import_job.result[:Tickets][:total] + current_request_count
            )
          end

          def update_required?
            return false if previous_page.blank?
            return false if previous_page == next_page
            current_request_count.present?
          end

          def current_request_count
            # access the internal instance method of the
            # Zendesk collection request to get the current
            # count of the endpoint (max. 1000)
            resource_collection_attribute.instance_variable_get(:@count)
          end

          def next_page
            # access the internal instance method of the
            # Zendesk collection request to get the next
            # page number of the endpoint
            resource_collection_attribute.instance_variable_get(:@next_page)
          end
        end
      end
    end
  end
end
