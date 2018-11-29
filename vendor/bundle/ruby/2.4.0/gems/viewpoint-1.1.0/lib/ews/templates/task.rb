module Viewpoint::EWS
  module Template
  # Template for creating Tasks
  # @see http://msdn.microsoft.com/en-us/library/exchange/aa564765.aspx
  class Task < OpenStruct

      # Available parameters with the required ordering
      PARAMETERS = %w{mime_content item_id parent_folder_id item_class subject sensitivity body attachments
            date_time_received size categories in_reply_to is_submitted is_draft is_from_me is_resend
            is_unmodified internet_message_headers date_time_sent date_time_created response_objects
            reminder_due_by reminder_is_set reminder_minutes_before_start display_cc display_to
            has_attachments extended_property culture actual_work assigned_time billing_information
            change_count companies complete_date contacts delegation_state delegator due_date
            is_assignment_editable is_complete is_recurring is_team_task mileage owner percent_complete
            recurrence start_date status status_description total_work effective_rights last_modified_name
            last_modified_time is_associated web_client_read_form_query_string
            web_client_edit_form_query_string conversation_id unique_body 
      }.map(&:to_sym).freeze

      # Returns a new Task template
      def initialize(opts = {})
        super opts.dup
      end

      # EWS CreateItem container
      # @return [Hash]
      def to_ews_create
        structure = {}

        if self.saved_item_folder_id
          if self.saved_item_folder_id.kind_of?(Hash)
            structure[:saved_item_folder_id] = saved_item_folder_id
          else
            structure[:saved_item_folder_id] = {id: saved_item_folder_id}
          end
        end

        structure[:items] = [{task: to_ews_item}]
        structure
      end

      # EWS Item hash
      #
      # Puts all known parameters in the required ordering and structure
      # @return [Hash]
      def to_ews_item
        item_parameters = {}
        PARAMETERS.each do |key|
          if !(value = self.send(key)).nil?

            # Convert non duplicable values to String
            case value
              when NilClass, FalseClass, TrueClass, Symbol, Numeric
                value = value.to_s
            end

            # Convert attributes
            case key
              when :start_date, :due_date
                item_parameters[key] = {text: value.respond_to?(:iso8601) ? value.iso8601 : value}
              when :body
                item_parameters[key] = {body_type: self.body_type || 'Text', text: value.to_s}
              else
                item_parameters[key] = value
            end
          end
        end

        item_parameters
      end

    end
  end
end
