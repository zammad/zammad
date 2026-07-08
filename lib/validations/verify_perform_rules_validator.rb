# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Validations::VerifyPerformRulesValidator < ActiveModel::EachValidator
  CHECK_PRESENT = {
    'article.note'                => %w[body subject internal],
    'notification.email'          => %w[body recipient subject],
    'notification.sms'            => %w[body recipient],
    'notification.webhook'        => %w[webhook_id],
    'ai.ai_agent'                 => %w[ai_agent_id],
    'x-zammad-ticket-owner_id'    => %w[value], # PostmasterFilter
    'x-zammad-ticket-customer_id' => %w[value], # PostmasterFilter
  }.freeze

  # Tag actions (add/remove) split their value into a tag list; a blank value
  #   yields an empty list and schedules nothing, so it must not be saved.
  #   `ticket.tags` is used by Trigger/Job/Macro, the `x-zammad-*` variants by
  #   PostmasterFilter. Other perform actions may legitimately clear a field
  #   with a blank value, so only tag actions are checked here.
  CHECK_TAGS_PRESENT = %w[
    ticket.tags
    x-zammad-ticket-tags
    x-zammad-ticket-followup-tags
  ].freeze

  CHECK_SPECIFIC_PRESENT = %w[
    ticket.customer_id
    ticket.organization_id
    ticket.owner_id
  ].freeze

  def validate_each(record, attribute, value)
    return if !value.is_a? Hash

    check_present(record, attribute, value)
    check_specific_present(record, attribute, value)
    check_tags_present(record, attribute, value)
    check_pending_time_present(record, value)
  end

  private

  def check_present(record, attribute, value)
    check_present_missing(value)
      .each do |key, inner|
        add_error(record, attribute, key, inner)
      end
  end

  def check_present_missing(value)
    CHECK_PRESENT.each_with_object([]) do |(key, attrs), result|
      next if !value[key].is_a? Hash

      attrs.each do |attr|
        result << [key, attr] if blank_attribute?(value[key][attr])
      end
    end
  end

  # A multi-value action (e.g. webhook_id / ai_agent_id) is missing when it has no
  #   non-blank entries, since blank entries are dropped at runtime and schedule nothing.
  def blank_attribute?(attribute_value)
    return attribute_value.compact_blank.blank? if attribute_value.is_a?(Array)

    attribute_value.blank?
  end

  def check_specific_present(record, attribute, value)
    check_specific_present_missing(value)
      .each do |key|
        add_error(record, attribute, key, 'value')
      end
  end

  def check_specific_present_missing(value)
    CHECK_SPECIFIC_PRESENT.each_with_object([]) do |key, result|
      next if !value[key].is_a? Hash
      next if value[key]['pre_condition'] != 'specific'

      result << key if value[key]['value'].blank?
    end
  end

  def check_tags_present(record, attribute, value)
    value.each do |key, meta|
      next if CHECK_TAGS_PRESENT.exclude?(key.to_s.downcase)
      next if !meta.is_a?(Hash)

      add_error(record, attribute, key, 'value') if blank_tag_value?(meta['value'])
    end
  end

  # Mirrors the runtime tag parsing (FilterProcessor#perform_filter_changes_tags,
  #   PerformChanges::Action::AttributeUpdates#normalized_tags): split on commas,
  #   strip, drop blanks. A value that normalizes to an empty list (nil, '',
  #   whitespace, an empty array, or separators-only like ',, ,,') schedules
  #   nothing and is treated as blank.
  def blank_tag_value?(raw_value)
    Array.wrap(raw_value)
      .flat_map { |tag| tag.to_s.split(',') }
      .map(&:strip)
      .compact_blank
      .blank?
  end

  def check_pending_time_present(record, value)
    return if !value.is_a?(Hash) || value.empty?
    return if pending_time_present?(value)
    return if !perform_sets_pending_state?(value)

    record.errors.add :base, __('The "Pending till" attribute is required for the selected state action.')
  end

  # Pending reminder and pending action both use ticket.pending_time
  # (@see Ticket.process_pending, Ticket::StateType::CATEGORIES[:pending]).
  def perform_sets_pending_state?(value)
    state_id = perform_ticket_state_id(value)
    return false if state_id.blank?

    Ticket::State.by_category(:pending).exists?(id: state_id)
  end

  def perform_ticket_state_id(value)
    raw = value.dig('ticket.state_id', 'value')
    return raw if raw.present?

    name = value.dig('ticket.state', 'value')
    return if name.blank?

    Ticket::State.lookup(name: name)&.id
  end

  def pending_time_present?(value)
    pending_time = value['ticket.pending_time']
    return false if !pending_time.is_a?(Hash)

    pending_time['value'].present?
  end

  def add_error(record, attribute, key, inner)
    record.errors.add :base, __("The required '%{attribute}' value for %{key}, %{inner} is missing!"), attribute: attribute, key: key, inner: inner
  end
end
