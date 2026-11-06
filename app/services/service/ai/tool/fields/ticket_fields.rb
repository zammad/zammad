# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A ticket's fields as the tools name them: the ticket's own fields as arguments of their own (state, owner, …), custom
#   fields as "fields.<name>" in the fields object, each with what Service::EntityAttribute::Metadata knows about it.
class Service::AI::Tool::Fields::TicketFields
  # @param ticket [Ticket] a saved ticket on the edit screen, or a new one on the create screen
  # @param changes [Hash{String => Object}] stored values by attribute name, such as the ID of another group
  # @param rules [Boolean] whether Core Workflow says what each field allows and requires
  # @return [Hash{String => Service::EntityAttribute::Metadata::Entry}] the fields a tool can set, by argument
  def self.settable(ticket:, user:, changes: {}, rules: true)
    screen = ticket.new_record? ? 'create_middle' : 'edit'

    Service::EntityAttribute::Metadata.with_current_user(user).execute(record: ticket, changes:, rules:, screen:).each_with_object({}) do |entry, fields|
      next if !entry.type.settable?

      fields[entry.attribute.editable ? "fields.#{entry.name}" : entry.type.data_key] = entry
    end
  end

  # The texts are written for the model, like every text a tool returns, so not translated.
  #
  # The first value Core Workflow does not allow, named with the values it does.
  #
  # @param fields [Hash{String => Service::EntityAttribute::Metadata::Entry}] the fields as the change leaves them, by argument
  # @param changes [Hash{String => Object}] stored values by attribute name
  # @return [String, nil]
  def self.not_allowed_text(fields, changes, subject:)
    changes.each do |name, value|
      argument, field = fields.find { |_key, candidate| candidate.name == name }
      next if field.nil? || field.allowed.nil? || Array(value).all? { |item| field.allowed.include?(item.to_s) }
      # The form lists the system user only as the saved owner, but every ticket may go back to nobody.
      next if name == 'owner_id' && value == Service::EntityAttribute::NameMatch::NOBODY_ID

      return "#{argument}: this value is not allowed for #{subject}. Allowed: #{Service::AI::Tool::Fields::EntityAttribute.values_text(Service::AI::Tool::Fields::EntityAttribute.values(field) || [])}.#{owner_groups_text(value, field.type.user) if name == 'owner_id'}"
    end

    nil
  end

  # An owner the group does not allow, named with the groups they may own tickets in, of those the user has access to.
  def self.owner_groups_text(owner_id, user)
    owner  = ::User.find_by(id: owner_id)
    groups = ::Group.where(id: owner.group_ids_access('full') & user.group_ids_access(%w[read create change])).reorder(:name) if owner
    return if groups.blank?

    " #{Service::AI::Tool::Fields::EntityAttribute.user_description(owner)} may own tickets in: #{groups.map { |group| Service::AI::Tool::Fields::EntityAttribute.group_name(group) }.join(', ')}."
  end

  # The fields left empty that Core Workflow then requires, by argument.
  #
  # @param record [ApplicationModel] whose stored values count where a change gives none
  def self.missing(fields, changes, record:)
    fields.select do |_argument, field|
      value = changes.fetch(field.name) { record[field.name] }

      field.shown && field.required && ChecksCoreWorkflow::EMPTY_VALUES.include?(value)
    end
  end

  def self.missing_text(missing, subject:)
    details = missing.map { |argument, field| "#{argument}#{format_hint(field.type)}" }

    "#{subject} needs #{details.join(', ')} as well. Ask the user for it, then call again with it."
  end

  # The form fields that ask for the missing values, each by its label in the user's language; nil where a form cannot
  #   ask for one of them.
  #
  # @return [Hash{String => Hash}, nil]
  def self.form_fields(missing, user:)
    schemas = missing.transform_values { |field| Service::AI::Tool::Fields::EntityAttribute.form_schema(field) }
    return if schemas.values.any?(&:nil?)

    schemas.to_h do |argument, schema|
      [argument, schema.merge(title: Translation.translate(user.locale, missing[argument].attribute.display))]
    end
  end

  def self.format_hint(type)
    schema = type.value_schema
    return ' (date and time, ISO 8601)' if schema[:format] == 'date-time'
    return ' (date, YYYY-MM-DD)' if schema[:format] == 'date'

    ''
  end
end
