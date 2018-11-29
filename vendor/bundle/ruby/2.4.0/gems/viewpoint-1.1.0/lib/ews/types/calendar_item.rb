module Viewpoint::EWS::Types
  class CalendarItem
    include Viewpoint::EWS
    include Viewpoint::EWS::Types
    include Viewpoint::EWS::Types::Item
    include Viewpoint::StringUtils

    CALENDAR_ITEM_KEY_PATHS = {
      recurring?:   [:is_recurring, :text],
      meeting?:     [:is_meeting, :text],
      cancelled?:   [:is_cancelled, :text],
      duration:     [:duration, :text],
      time_zone:    [:time_zone, :text],
      start:        [:start, :text],
      end:          [:end, :text],
      location:     [:location, :text],
      all_day?:     [:is_all_day_event, :text],
      legacy_free_busy_status: [:legacy_free_busy_status, :text],
      my_response_type:   [:my_response_type, :text],
      organizer: [:organizer, :elems, 0, :mailbox, :elems],
      optional_attendees: [:optional_attendees, :elems ],
      required_attendees: [:required_attendees, :elems ],
      recurrence: [:recurrence, :elems ],
      deleted_occurrences: [:deleted_occurrences, :elems ],
      modified_occurrences: [:modified_occurrences, :elems ]
   }

    CALENDAR_ITEM_KEY_TYPES = {
      start:        ->(str){DateTime.parse(str)},
      end:          ->(str){DateTime.parse(str)},
      recurring?:   ->(str){str.downcase == 'true'},
      meeting?:     ->(str){str.downcase == 'true'},
      cancelled?:   ->(str){str.downcase == 'true'},
      all_day?:     ->(str){str.downcase == 'true'},
      organizer: :build_mailbox_user,
      optional_attendees: :build_attendees_users,
      required_attendees: :build_attendees_users,
      deleted_occurrences: :build_deleted_occurrences,
      modified_occurrences: :build_modified_occurrences
    }
    CALENDAR_ITEM_KEY_ALIAS = {}

    # Updates the specified item attributes
    #
    # Uses `SetItemField` if value is present and `DeleteItemField` if value is nil
    # @param updates [Hash] with (:attribute => value)
    # @param options [Hash]
    # @option options :conflict_resolution [String] one of 'NeverOverwrite', 'AutoResolve' (default) or 'AlwaysOverwrite'
    # @option options :send_meeting_invitations_or_cancellations [String] one of 'SendToNone' (default), 'SendOnlyToAll',
    #   'SendOnlyToChanged', 'SendToAllAndSaveCopy' or 'SendToChangedAndSaveCopy'
    # @return [CalendarItem, false]
    # @example Update Subject and Body
    #   item = #...
    #   item.update_item!(subject: 'New subject', body: 'New Body')
    # @see http://msdn.microsoft.com/en-us/library/exchange/aa580254.aspx
    # @todo AppendToItemField updates not implemented
    def update_item!(updates, options = {})
      item_updates = []
      updates.each do |attribute, value|
        item_field = FIELD_URIS[attribute][:text] if FIELD_URIS.include? attribute
        field = {field_uRI: {field_uRI: item_field}}

        if value.nil? && item_field
          # Build DeleteItemField Change
          item_updates << {delete_item_field: field}
        elsif item_field
          # Build SetItemField Change
          item = Viewpoint::EWS::Template::CalendarItem.new(attribute => value)

          # Remap attributes because ews_builder #dispatch_field_item! uses #build_xml!
          item_attributes = item.to_ews_item.map do |name, value|
            if value.is_a? String
              {name => {text: value}}
            elsif value.is_a? Hash
              node = {name => {}}
              value.each do |attrib_key, attrib_value|
                attrib_key = camel_case(attrib_key) unless attrib_key == :text
                node[name][attrib_key] = attrib_value
              end
              node
            else
              {name => value}
            end
          end

          item_updates << {set_item_field: field.merge(calendar_item: {sub_elements: item_attributes})}
        else
          # Ignore unknown attribute
        end
      end

      if item_updates.any?
        data = {}
        data[:conflict_resolution] = options[:conflict_resolution] || 'AutoResolve'
        data[:send_meeting_invitations_or_cancellations] = options[:send_meeting_invitations_or_cancellations] || 'SendToNone'
        data[:item_changes] = [{item_id: self.item_id, updates: item_updates}]
        rm = ews.update_item(data).response_messages.first
        if rm && rm.success?
          self.get_all_properties!
          self
        else
          raise EwsCreateItemError, "Could not update calendar item. #{rm.code}: #{rm.message_text}" unless rm
        end
      end

    end

    def duration_in_seconds
      iso8601_duration_to_seconds(duration)
    end


    private


    def key_paths
      super.merge(CALENDAR_ITEM_KEY_PATHS)
    end

    def key_types
      super.merge(CALENDAR_ITEM_KEY_TYPES)
    end

    def key_alias
      super.merge(CALENDAR_ITEM_KEY_ALIAS)
    end


  end
end
