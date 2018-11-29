module Viewpoint::EWS
  module Template
  # Template for creating CalendarItems
  # @see http://msdn.microsoft.com/en-us/library/exchange/aa564765.aspx
  class CalendarItem < OpenStruct

      # Available parameters with the required ordering
      PARAMETERS = %w{mime_content item_id parent_folder_id item_class subject sensitivity body attachments
        date_time_received size categories in_reply_to is_submitted is_draft is_from_me is_resend is_unmodified
        internet_message_headers date_time_sent date_time_created response_objects reminder_due_by reminder_is_set
        reminder_minutes_before_start display_cc display_to has_attachments extended_property culture start end
        original_start is_all_day_event legacy_free_busy_status location when is_meeting is_cancelled is_recurring
        meeting_request_was_sent is_response_requested calendar_item_type my_response_type organizer
        required_attendees optional_attendees resources conflicting_meeting_count adjacent_meeting_count
        conflicting_meetings adjacent_meetings duration time_zone appointment_reply_time appointment_sequence_number
        appointment_state recurrence first_occurrence last_occurrence modified_occurrences deleted_occurrences
        meeting_time_zone start_time_zone end_time_zone conference_type allow_new_time_proposal is_online_meeting
        meeting_workspace_url net_show_url effective_rights last_modified_name last_modified_time is_associated
        web_client_read_form_query_string web_client_edit_form_query_string conversation_id unique_body
      }.map(&:to_sym).freeze

      # Returns a new CalendarItem template
      def initialize(opts = {})
        super opts.dup
      end

      # EWS CreateItem container
      # @return [Hash]
      def to_ews_create(opts = {})
        structure = {}
        structure[:message_disposition] = (draft ? 'SaveOnly' : 'SendAndSaveCopy')
        # options
        structure[:send_meeting_invitations] = (opts.has_key?(:send_meeting_invitations) ? opts[:send_meeting_invitations] : 'SendToNone')

        if self.saved_item_folder_id
          if self.saved_item_folder_id.kind_of?(Hash)
            structure[:saved_item_folder_id] = saved_item_folder_id
          else
            structure[:saved_item_folder_id] = {id: saved_item_folder_id}
          end
        end

        structure[:items] = [{calendar_item: to_ews_item}]
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
              when :start, :end
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
