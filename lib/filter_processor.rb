# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FilterProcessor
  OPERATORS_WITH_MULTIPLE_VALUES = [
    'is any of',
    'is none of',
    'starts with one of',
    'ends with one of',
  ].freeze

  attr_reader :filter, :mail, :context

  def initialize(filter, mail)
    @filter = filter
    @mail = mail
    @context = { match_data: {} }
  end

  def process
    return if !filter_matches?

    perform_filter_changes
  end

  def filter_matches?

    min_one_rule_exists = false

    @filter[:match].each do |key, meta|

      next if meta.blank? || meta['value'].blank?

      value = @mail[ key.downcase.to_sym ]
      match_rule = meta['value']
      min_one_rule_exists = true
      operator = meta[:operator]

      human_match_rule = match_rule

      if OPERATORS_WITH_MULTIPLE_VALUES.include?(operator) && !match_rule.instance_of?(Array)
        match_rule = [match_rule]
        human_match_rule = match_rule.join(', ')
      end

      if !rule_matches?(operator, match_rule, value)
        Rails.logger.debug { "  not matching: key '#{key.downcase}' #{operator} '#{human_match_rule}'" }
        return false
      end

      Rails.logger.info { "  matching: key '#{key.downcase}' #{operator} '#{human_match_rule}'" }
    rescue => e
      Rails.logger.error "can't use match rule '#{human_match_rule}' on '#{value}'"
      Rails.logger.error e.inspect
      return false
    end

    min_one_rule_exists
  end

  def rule_matches?(operator, match_rule, value)
    case operator
    when 'contains not'
      !FilterProcessor::Match::Contains.match(value: value, match_rule: match_rule)
    when 'contains'
      FilterProcessor::Match::Contains.match(value: value, match_rule: match_rule)
    when 'is any of'
      FilterProcessor::Match::IsAnyOf.match(value: value, match_rule: match_rule)
    when 'is none of'
      !FilterProcessor::Match::IsAnyOf.match(value: value, match_rule: match_rule)
    when 'starts with one of'
      FilterProcessor::Match::StartsWith.match(value: value, match_rule: match_rule)
    when 'ends with one of'
      FilterProcessor::Match::EndsWith.match(value: value, match_rule: match_rule)
    when 'matches regex'
      FilterProcessor::Match::EmailRegex.match(value: value, match_rule: match_rule, context:)
    when 'does not match regex'
      !FilterProcessor::Match::EmailRegex.match(value: value, match_rule: match_rule)
    else
      Rails.logger.info { "  Invalid operator in match #{meta.inspect}" }
      false
    end
  end

  def perform_filter_changes
    @filter[:perform].each do |key, meta|
      next if !Channel::EmailParser.check_attributes_by_x_headers(key, meta['value'])

      Rails.logger.debug { "  perform '#{key.downcase}' = '#{meta.inspect}'" }

      next if perform_filter_changes_tags(key: key, meta: meta)
      next if perform_filter_changes_date(key: key, meta: meta)

      perform_filter_changes_regular(key: key, meta: meta)

    end
  end

  def perform_filter_changes_general(key:, meta:)
    @mail[ key.downcase.to_sym ] = meta['value']
    @mail[:"#{key.downcase}-source"] = @filter
  end

  def perform_filter_changes_tags(key:, meta:)
    return if %w[x-zammad-ticket-tags x-zammad-ticket-followup-tags].exclude?(key.downcase)

    mail_header_key         = key.downcase.to_sym
    current_tags            = @mail[mail_header_key].to_s.split(',').map(&:strip).compact_blank
    change_tags             = meta['value'].split(',').map(&:strip).compact_blank

    case meta['operator']
    when 'add'
      change_tags.each do |tag|
        current_tags |= [tag]
        @mail[:"#{key.downcase}-source"] = @filter
      end
    when 'remove'
      change_tags.each do |tag|
        current_tags -= [tag]
        @mail[:"#{key.downcase}-source"] = @filter
      end
    end

    @mail[mail_header_key] = current_tags.join(',')

    true
  end

  def perform_filter_changes_regular(key:, meta:)
    value = meta['value']

    # Replace regex placeholders with the actual match data from the filter matching process
    # Uses namespaced placeholders like #{regexp.1} for numbered captures and #{regexp.name} for named captures
    # https://github.com/zammad/zammad/issues/5815
    if value.is_a?(String)
      value = value.gsub(%r{#\{regexp\.(.+?)\}}) do
        @context[:match_data][$1] || '-'
      end
    end

    @mail[ key.downcase.to_sym ] = value
    @mail[:"#{key.downcase}-source"] = @filter

    true
  end

  def perform_filter_changes_date(key:, meta:)
    return if key !~ %r{x-zammad-ticket-(?:followup-)?(.*)}

    object_attribute = ObjectManager::Attribute.for_object('Ticket').find_by(name: $1, data_type: %w[datetime date])
    return if object_attribute.blank?

    new_value = if meta['operator'] == 'relative'
                  TimeRangeHelper.relative(range: meta['range'], value: meta['value'])
                else
                  meta['value']
                end

    if new_value
      @mail[ key.downcase.to_sym ] = if object_attribute[:data_type] == 'datetime'
                                       new_value.to_datetime
                                     else
                                       new_value.to_date
                                     end
      @mail[:"#{key.downcase}-source"] = @filter
    end

    true
  end
end
