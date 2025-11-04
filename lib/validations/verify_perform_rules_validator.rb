# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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

  CHECK_SPECIFIC_PRESENT = %w[
    ticket.customer_id
    ticket.organization_id
    ticket.owner_id
  ].freeze

  def validate_each(record, attribute, value)
    return if !value.is_a? Hash

    check_present(record, attribute, value)
    check_specific_present(record, attribute, value)
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
        result << [key, attr] if value[key][attr].blank?
      end
    end
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

  def add_error(record, attribute, key, inner)
    record.errors.add :base, __("The required '%{attribute}' value for %{key}, %{inner} is missing!"), attribute: attribute, key: key, inner: inner
  end
end
