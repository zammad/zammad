# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec::Matchers.define :include_assets_of do
  match do |actual|
    expected_array.all? { |elem| find_assets_of(elem, actual) }
  end

  match_when_negated do |actual|
    expected_array.none? { |elem| find_assets_of(elem, actual) }
  end

  description do
    "include assets of #{expected_name}"
  end

  failure_message do |actual|
    list = expected_array.reject { |elem| find_assets_of(elem, actual) }
    "Expected hash to include, but not included:\n#{items_for_message(list)}"
  end

  failure_message_when_negated do |actual|
    list = expected_array.select { |elem| find_assets_of(elem, actual) }
    "Expected hash to not include, but was included:\n#{items_for_message(list)}"
  end

  def items_for_message(items)
    items
      .map { |elem| "- #{item_name(elem)}" }
      .join("\n")
  end

  def expected_name
    expected_array
      .map { |elem| item_name(elem) }
      .join(', ')
  end

  def item_name(item)
    "#{item.class.name}##{item.id}"
  end

  def expected_array
    Array(expected)
  end

  # Finds corresponding object's data in assets hash
  #
  # @param [ActiveRecord::Base] object to look for
  # @param [Hash] assets hash to use
  #
  # @example
  #  assets = Ticket.first.assets
  #  find_assets_of(Ticket.first, assets)
  #
  # @return [Hash, nil]
  def find_assets_of(object, actual)
    actual.dig(object.class.name.gsub(%r{::}, ''), object.id.to_s)
  end
end

RSpec::Matchers.define_negated_matcher :not_include_assets_of, :include_assets_of
