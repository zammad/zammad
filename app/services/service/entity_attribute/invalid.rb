# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A value a field cannot take, with what a client needs to say why in its own words: the candidates a name fits, the
#   values the field allows, or the kind of value it takes. Only values the user may use are among them.
class Service::EntityAttribute::Invalid < StandardError
  attr_reader :code, :reason, :field, :value, :kind, :items, :count, :details

  # @param code [String] 'ambiguous', 'invalid_value' or 'not_settable'
  # @param reason [Symbol] why: :ambiguous, :partial (a name that fits one record only by a part, where the caller
  #   matches strictly), :unknown (no value of the list), :no_match (no record), :not_choosable (a record the user may
  #   not choose here), :not_settable, or the kind of value the field takes, such as :text
  # @param field [String] the field or the filter the value was given for
  # @param kind [String, nil] what the values are, such as 'agent' or 'option'
  # @param items [Array] the candidates the value fits, or the values the field allows: records, or an option's key and
  #   label
  # @param count [Integer, nil] how many candidates there are, where items holds the first of them only
  # @param details [Hash] the bounds of the value, such as maximum: 100
  def initialize(code, reason:, field:, value: nil, kind: nil, items: [], count: nil, details: {})
    super("#{field}: #{reason}")

    @code    = code
    @reason  = reason
    @field   = field
    @value   = value
    @kind    = kind
    @items   = items
    @count   = count || items.size
    @details = details
  end
end
