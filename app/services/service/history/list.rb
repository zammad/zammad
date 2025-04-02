# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Create a list of history events for a given object.
#
# An entry in the list contains the following information:
# - created_at: The timestamp when the event was created.
# - issuer:     The issuer who created the event.
# - action:     The type of the event.
# - object:     The object the event is related to.
# - attribute:  The attribute of the object that was changed.
# - changes:    The changes that were made to the attribute.
#
# The object and issuer attributes contain a pseudo object if the related
# object doesn't exist anymore with the following information:
# - klass: The name of the object's class.
# - info: Additional information about the object.
#
# Example:
#
#  Service::History::List.new(current_user:).execute(object: ticket)
#  # => [
#  #      {
#  #        created_at: ActiveRecord::DateTime,
#  #        issuer:     User,
#  #        action:     'created',
#  #        object:     Ticket,
#  #        attribute:  nil,
#  #        changes:    { from: nil, to: nil }
#  #      },
#  #      {
#  #        created_at: ActiveRecord::DateTime,
#  #        issuer:     User,
#  #        action:     'created',
#  #        object:     Ticket::Article,
#  #        attribute:  nil,
#  #        changes:    { from: nil, to: nil }
#  #      {
#  #        created_at: ActiveRecord::DateTime,
#  #        issuer:     PostmasterFilter,
#  #        action:     'updated',
#  #        object:     Ticket,
#  #        attribute:  'title',
#  #        changes:    { from: 'Old title', to: 'New title' }
#  #      }
#  #    ]
class Service::History::List < Service::BaseWithCurrentUser
  include Service::History::Concerns::FixEventObject

  def execute(object:)
    @object = object

    Pundit.authorize(current_user, object, :show?)
    raise __('Object does not support history') if !object.class.const_defined?(:HasHistory)

    fetch_list(object)
  end

  private

  def fetch_list(object)
    History.list(
      object.class.name,
      object.id,
      object.history_relation_object,
      raw: true
    ).map { |entry| event(entry) }
  end

  def event(entry)
    event = {
      created_at: entry.created_at,
      issuer:     issuer(entry),
      action:     entry.history_type.name,
      object:     object(entry),
      attribute:  entry.history_attribute&.name,
      changes:    changes(entry),
    }

    fix_event_object(event, entry)

    event
  end

  def issuer(entry)
    if entry.sourceable_type.present?
      klass = entry.sourceable_type.constantize
      klass.find(entry.sourceable_id)
    else
      User.find(entry.created_by_id)
    end
  rescue ActiveRecord::RecordNotFound
    {
      klass: entry.sourceable_type.presence || 'User',
      info:  entry.sourceable_name.presence
    }
  end

  def object(entry)
    return { klass: entry.history_object.name } if entry.history_object.name == @object.class.name && entry.o_id == @object.id

    begin
      klass = entry.history_object.name.constantize
      klass.find(entry.o_id)
    rescue ActiveRecord::RecordNotFound
      { klass: entry.history_object.name }
    end
  end

  def changes(entry)
    {
      from: entry.value_from,
      to:   entry.value_to
    }
  end
end
