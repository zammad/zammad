# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Service::History::Concerns::FixEventObject
  extend ActiveSupport::Concern

  included do
    private

    def fix_event_object(event, entry)
      fix_mention_object(event, entry)
      fix_merge_object(event, entry)
    end

    # The related mention object is always a User. The action is suffixed with
    # `_mention` to distinguish it from other actions.
    def fix_mention_object(event, entry)
      return if entry.history_object.name != 'Mention'

      event[:action] = "#{event[:action]}_mention"
      event[:object] = __get_event_object_or_class_name(User, entry.value_to)
    end

    # The related merge object is always a Ticket.
    def fix_merge_object(event, entry)
      return if entry.history_type.name.exclude?('merge')

      id = entry.history_type.name.include?('received') ? entry.id_from : entry.id_to
      event[:object] = __get_event_object_or_class_name(Ticket, id)
    end

    def __get_event_object_or_class_name(klass, id)
      klass.find(id)
    rescue ActiveRecord::RecordNotFound
      { klass: klass.name }
    end
  end
end
