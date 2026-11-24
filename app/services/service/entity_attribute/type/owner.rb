# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A ticket's owner: an active agent by name, email or login, "me", or "nobody".
class Service::EntityAttribute::Type::Owner < Service::EntityAttribute::Type::Relation
  handles 'select', relation: 'User'

  NOBODY = 'nobody'.freeze

  def label(value)
    return NOBODY if value.to_i == Service::EntityAttribute::NameMatch::NOBODY_ID

    super
  end

  def choices(allowed: nil)
    nobody = allowed.nil? || allowed.any? { |id| id.blank? || id.to_i == Service::EntityAttribute::NameMatch::NOBODY_ID }

    [([Service::EntityAttribute::NameMatch::NOBODY_ID.to_s, NOBODY] if nobody), *super].compact
  end

  def option_list_key(allowed: nil)
    [*super, name_format]
  end

  private

  # A user's record changes with every login, so the key holds what a label reads in place of the time of that change.
  def option_list_key_columns
    %i[firstname lastname email phone mobile login]
  end

  # Every ticket may go back to nobody, whatever the group allows.
  def convert(value, allowed:)
    case value.to_s.squish.downcase
    when 'me'
      return user if choosable(allowed).exists?(id: user.id)

      raise not_choosable('me', allowed)
    when NOBODY
      ::User.find(Service::EntityAttribute::NameMatch::NOBODY_ID)
    else
      owner(value.to_s.squish, allowed)
    end
  end

  # An agent who may not own the ticket here is no candidate: the error names those who may.
  def owner(value, allowed)
    Service::EntityAttribute::NameMatch.user(value, choosable(allowed), filter: 'owner', kind: 'agent', strict: true)
  rescue Invalid => e
    raise if e.code != 'invalid_value'

    raise not_choosable(value, allowed)
  end

  # Nobody among the owners, as the system user, where the ticket may go back to nobody.
  def not_choosable(value, allowed)
    owners = choices(allowed:).map { |id, _label| id.to_i }

    Invalid.new('invalid_value', reason: :not_choosable, field: 'owner', value:, kind: 'agent', items: ::User.where(id: owners).index_by(&:id).values_at(*owners))
  end

  def record_class
    ::User
  end

  # Core Workflow offers no owner who lost access to the group, the ticket's own neither.
  def own_value
    nil
  end

  def every
    ::User.where(active: true, id: ::User.with_permissions('ticket.agent').select(:id))
      .where.not(id: Service::EntityAttribute::NameMatch::NOBODY_ID)
  end

  # The active agents the user may see, without the system user.
  def candidates
    UserPolicy::Scope.new(user, ::User).resolve
      .where(id: ::User.with_permissions('ticket.agent').select(:id))
      .where.not(id: Service::EntityAttribute::NameMatch::NOBODY_ID)
  end

  def record_label(record)
    record.fullname
  end

  # A user without name, email and phone has the login.
  def option_label(record)
    record.fullname(name_format:).presence || record.login
  end

  # Read once, so that a list reads in the format its key names, also where the setting changes in between.
  def name_format
    @name_format ||= Setting.get('user_name_format')
  end
end
