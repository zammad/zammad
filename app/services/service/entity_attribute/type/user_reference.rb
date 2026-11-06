# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A user, stored by ID and given by name, email or login: one the user may see. A record's own user, such as a ticket's
#   customer, is set as the user itself under its name without "_id", as relations are; a custom field by its ID.
class Service::EntityAttribute::Type::UserReference < Service::EntityAttribute::Type
  handles 'user_autocompletion'

  def label(value)
    named = ::User.find_by(id: value)
    return if named.nil? || (!unscoped? && !Pundit.policy(user, named).show?)

    named.fullname
  end

  def settable?
    true
  end

  def value_schema
    { type: 'string' }
  end

  def data_key
    attribute.editable ? name : name.delete_suffix('_id')
  end

  private

  def convert(value, **)
    scope = UserPolicy::Scope.new(user, ::User).resolve.where.not(id: Service::EntityAttribute::NameMatch::NOBODY_ID)

    named = Service::EntityAttribute::NameMatch.user(value.to_s.squish, scope, filter: data_key, kind: 'user', strict: true)

    attribute.editable ? named.id : named
  end
end
