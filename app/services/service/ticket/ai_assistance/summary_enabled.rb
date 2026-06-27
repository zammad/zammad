# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::AIAssistance::SummaryEnabled < Service::Base
  CACHE_EXPIRES_IN = 5.minutes

  DYNAMIC_OPERATORS = [
    'after (relative)',
    'before (relative)',
    'from (relative)',
    'till (relative)',
    'today',
    'within last (relative)',
    'within next (relative)',
  ].freeze

  RELATED_SELECTOR_PREFIXES = %w[customer organization].freeze

  attr_reader :ticket

  requires_current_user!

  def initialize(ticket:)
    @ticket = ticket
  end

  def execute
    return false if !Setting.get('ai_provider')
    return false if !Setting.get('ai_assistance_ticket_summary')
    return false if ticket.state.state_type.name == 'merged'
    return true if selector.blank?

    Rails.cache.fetch(cache_key, **selector_cache_options) { selector_matches? }
  end

  private

  def cache_key
    [
      self.class.name,
      ticket.cache_key_with_version,
      current_user_cache_key_with_version,
      condition_checksum,
    ].compact.join('/')
  end

  def condition_checksum
    Digest::SHA256.hexdigest(condition.to_json)
  end

  def selector_matches?
    ticket_count, = Ticket.selectors(condition, limit: 1, current_user:, access: 'ignore')
    ticket_count.to_i.positive?
  end

  def selector_cache_options
    return {} if !selector_requires_bounded_cache?

    { expires_in: CACHE_EXPIRES_IN }
  end

  def selector_requires_bounded_cache?
    dynamic_operator_used? ||
      current_user_organization_pre_condition_used? ||
      related_selector_used?
  end

  def dynamic_operator_used?
    DYNAMIC_OPERATORS.any? do |operator|
      selector_value_used?('operator', operator)
    end
  end

  def current_user_organization_pre_condition_used?
    selector_value_used?('pre_condition', 'current_user.organization_id')
  end

  def current_user_cache_key_with_version
    return if !selector_uses_current_user?

    current_user.cache_key_with_version
  end

  def selector_uses_current_user?
    selector_value_prefix_used?('pre_condition', 'current_user.')
  end

  def related_selector_used?
    RELATED_SELECTOR_PREFIXES.any? do |prefix|
      selector_string.include?(%("#{prefix}.))
    end
  end

  def selector_string
    @selector_string ||= selector.to_s
  end

  def selector_value_used?(key, value)
    selector_string.include?(%("#{key}" => "#{value}"))
  end

  def selector_value_prefix_used?(key, value)
    selector_string.include?(%("#{key}" => "#{value}))
  end

  def condition
    @condition ||= begin
      selector.merge(
        'ticket.id' => {
          'operator' => 'is',
          'value'    => ticket.id,
        }
      )
    end
  end

  def selector
    @selector ||= begin
      setting = Setting.get('ai_assistance_ticket_summary_selector')

      if setting.blank?
        {}
      else
        setting[:condition] || setting['condition'] || {}
      end
    end
  end

end
