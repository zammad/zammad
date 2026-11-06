# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# What the tools add to the field layer (Service::EntityAttribute) for the model: its errors as texts, the names that
#   tell two records of the same name apart, and the form a client asks its user with.
module Service::AI::Tool::Fields::EntityAttribute
  CANDIDATES   = Service::EntityAttribute::NameMatch::CANDIDATES
  VALID_VALUES = 20

  # The types a form of the client takes; a list of choices is a string with an enum, at most FORM_OPTIONS of them.
  FORM_TYPES   = %w[string integer number boolean].freeze
  FORM_OPTIONS = 50

  Relation = Service::EntityAttribute::Type::Relation

  # A value a tool cannot take, with a message the model can act on.
  class Invalid < StandardError
    attr_reader :code

    def initialize(code, message)
      super(message)
      @code = code
    end
  end

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  VALUE_TEXTS = {
    text:       ->(_error) { 'give the value as text.' },
    too_long:   ->(error) { "the value has #{error.details[:length]} characters; at most #{error.details[:maximum]} fit." },
    plain_text: ->(_error) { 'give the value as plain text.' },
    texts:      ->(_error) { 'give each value as text.' },
    boolean:    ->(_error) { 'give the value as true or false.' },
    integer:    ->(_error) { 'give the value as a whole number.' },
    minimum:    ->(error) { "the value must be at least #{error.details[:minimum]}." },
    maximum:    ->(error) { "the value must be at most #{error.details[:maximum]}." },
    date:       ->(error) { "\"#{error.value}\" is no date; give it as YYYY-MM-DD." },
    date_time:  ->(error) { "\"#{error.value}\" is no date and time; give it as ISO 8601, such as 2026-10-26T09:00:00+02:00." },
  }.freeze

  class << self
    # @return [Object] what the record stores for the value
    # @raise [Invalid]
    def resolve(type, value, allowed: nil)
      type.resolve(value, allowed:)
    rescue Service::EntityAttribute::Invalid => e
      raise invalid(e)
    end

    # A name the field layer matches, its error as a text.
    #
    # @param hint [String, nil] how to name one record where the name fits several
    # @raise [Invalid]
    def matching(hint: nil)
      yield
    rescue Service::EntityAttribute::Invalid => e
      raise invalid(e, hint:)
    end

    def invalid(error, hint: nil)
      Invalid.new(error.code, message(error, hint:))
    end

    def message(error, hint: nil)
      named = "#{error.field} \"#{error.value}\""

      case error.reason
      when :ambiguous     then "#{named} matches #{candidates_text(names(error.items), error.count, error.kind)}. #{hint || ambiguous_hint(error.items)}"
      when :partial       then "#{named} fits only by a part: #{names(error.items).join(', ')}. #{ambiguous_hint(error.items)}"
      when :unknown       then "#{named} does not exist. Valid #{error.kind.pluralize}: #{values_text(names(error.items))}."
      when :no_match      then "#{named} matches no #{error.kind}.#{" The closest: #{names(error.items).join(', ')}." if error.items.any?}"
      when :not_choosable then not_choosable_text(error, named)
      when :not_settable  then "#{error.field} cannot be set with this tool. Change it in Zammad."
      else "#{error.field}: #{VALUE_TEXTS.fetch(error.reason, ->(_error) { 'the value does not fit.' }).call(error)}"
      end
    end

    # The values a field allows, as the model tells them apart: an owner with the email.
    #
    # @param field [Service::EntityAttribute::Metadata::Entry]
    # @return [Array<String>, nil]
    def values(field)
      choices = field.choices
      return if choices.nil?
      return choices.map(&:last) if !field.type.is_a?(Relation)

      records = field.type.records(allowed: field.allowed).index_by { |record| record.id.to_s }

      choices.map { |key, label| records[key] ? name_of(records[key]) : label }
    end

    # A stored value as the model tells it apart from others: an owner with the email.
    def value_text(field, value)
      return field.value_text(value) if !field.type.is_a?(Relation) || value.blank?

      found = field.type.record_for(value)
      found && name_of(found)
    end

    # The field as a field of a form the client shows its user, when Zammad needs a value only the user knows.
    #
    # @return [Hash, nil] a flat JSON Schema property, as a form takes it; nil for a field a form cannot ask for
    def form_schema(field)
      schema = field.type.value_schema
      return if FORM_TYPES.exclude?(schema[:type])

      choices = values(field)
      return schema if choices.nil?

      { type: 'string', enum: choices } if choices.any? && choices.size <= FORM_OPTIONS
    end

    def name_of(item)
      case item
      when ::User  then item.id == Service::EntityAttribute::NameMatch::NOBODY_ID ? Service::EntityAttribute::Type::Owner::NOBODY : user_description(item)
      when ::Group then group_name(item)
      when Array   then item.last
      else item.name
      end
    end

    # The email names a user where names repeat; without one, the ID and the organization do.
    def user_description(found)
      details = found.email.present? ? [found.email] : ["ID #{found.id}", found.organization&.name]

      "#{found.fullname} (#{details.compact.join(', ')})"
    end

    def group_name(group)
      Service::EntityAttribute::Type::TicketGroup.path(group)
    end

    def candidates_text(names, count, kind)
      more = count > CANDIDATES ? ", and #{count - CANDIDATES} more" : ''

      "#{count} #{kind.pluralize(count)}: #{names.first(CANDIDATES).join(', ')}#{more}"
    end

    def values_text(names)
      return 'none' if names.empty?

      more = names.size > VALID_VALUES ? ", and #{names.size - VALID_VALUES} more" : ''

      "#{names.first(VALID_VALUES).join(', ')}#{more}"
    end

    private

    def names(items)
      items.map { |item| name_of(item) }
    end

    def ambiguous_hint(items)
      items.first.is_a?(::User) ? 'Use the email, or the ID where there is none.' : 'Use the full name.'
    end

    # Only an owner is a record the user may know but not choose here.
    def not_choosable_text(error, named)
      owners = values_text(names(error.items))
      return "#{named}: you may not own this ticket. Valid owners: #{owners}." if error.value == 'me'

      "#{named} matches no agent who may own this ticket. Valid owners: #{owners}."
    end
  end
  # rubocop:enable Zammad/DetectTranslatableString
end
