# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# process all database filter
module Channel::Filter::Database # rubocop:disable Metrics/ModuleLength

  OPERATORS_WITH_MULTIPLE_VALUES = [
    'is any of',
    'is none of',
    'starts with one of',
    'ends with one of',
  ].freeze

  def self.run(_channel, mail, _transaction_params)
    PostmasterFilter.where(active: true, channel: 'email').reorder(:name, :created_at).each do |filter|
      Rails.logger.debug { " process filter #{filter.name} ..." }
      perform_filter_changes(mail, filter) if filter_matches?(mail, filter)
    end
  end

  def self.filter_matches?(mail, filter)

    min_one_rule_exists = false

    filter[:match].each do |key, meta|

      next if meta.blank? || meta['value'].blank?

      value = mail[ key.downcase.to_sym ]
      match_rule = meta['value']
      min_one_rule_exists = true
      operator = meta[:operator]

      human_match_rule = match_rule

      if OPERATORS_WITH_MULTIPLE_VALUES.include?(operator) && !match_rule.instance_of?(Array)
        match_rule = [match_rule]
        human_match_rule = match_rule.join(', ')
      end

      if !rule_matches?(operator, match_rule, value)
        Rails.logger.debug { "  not matching content '#{key.downcase}' contains not #{human_match_rule}" }
        return false
      end

      Rails.logger.info { "  matching: content '#{key.downcase}' contains not #{human_match_rule}" }
    rescue => e
      Rails.logger.error "can't use match rule #{human_match_rule} on #{value}"
      Rails.logger.error e.inspect
      return false
    end

    min_one_rule_exists
  end

  def self.rule_matches?(operator, match_rule, value)
    case operator
    when 'contains not'
      value.blank? || !Channel::Filter::Match::Contains.match(value: value, match_rule: match_rule)
    when 'contains'
      value.present? && Channel::Filter::Match::Contains.match(value: value, match_rule: match_rule)
    when 'is any of'
      match_rule.any?(value)
    when 'is none of'
      match_rule.none?(value)
    when 'starts with one of'
      match_rule.any? { |rule_value| value.downcase.start_with? rule_value.downcase }
    when 'ends with one of'
      match_rule.any? { |rule_value| value.downcase.end_with? rule_value.downcase }
    when 'matches regex'
      value.present? && Channel::Filter::Match::EmailRegex.match(value: value, match_rule: match_rule)
    when 'does not match regex'
      value.blank? || !Channel::Filter::Match::EmailRegex.match(value: value, match_rule: match_rule)
    else
      Rails.logger.info { "  Invalid operator in match #{meta.inspect}" }
      false
    end
  end

  def self.perform_filter_changes(mail, filter)
    filter[:perform].each do |key, meta|
      next if !Channel::EmailParser.check_attributes_by_x_headers(key, meta['value'])

      Rails.logger.debug { "  perform '#{key.downcase}' = '#{meta.inspect}'" }

      next if perform_filter_changes_tags(mail: mail, filter: filter, key: key, meta: meta)
      next if perform_filter_changes_date(mail: mail, filter: filter, key: key, meta: meta)

      mail[ key.downcase.to_sym ] = meta['value']
      mail[:"#{key.downcase}-source"] = filter
    end
  end

  def self.perform_filter_changes_tags(mail:, filter:, key:, meta:)
    return if %w[x-zammad-ticket-tags x-zammad-ticket-followup-tags].exclude?(key.downcase)

    mail_header_key         = key.downcase.to_sym
    mail[mail_header_key] ||= []
    tags                    = meta['value'].split(',').map(&:strip).select(&:present?)

    case meta['operator']
    when 'add'
      tags.each do |tag|
        next if mail[mail_header_key].include?(tag)

        mail[mail_header_key].push tag
        mail[:"#{key.downcase}-source"] = filter
      end
    when 'remove'
      tags.each do |tag|
        mail[mail_header_key] -= [tag]
        mail[:"#{key.downcase}-source"] = filter
      end
    end

    true
  end

  def self.perform_filter_changes_date(mail:, filter:, key:, meta:)
    return if key !~ %r{x-zammad-ticket-(?:followup-)?(.*)}

    object_attribute = ObjectManager::Attribute.for_object('Ticket').find_by(name: $1, data_type: %w[datetime date])
    return if object_attribute.blank?

    new_value = if meta['operator'] == 'relative'
                  TimeRangeHelper.relative(range: meta['range'], value: meta['value'])
                else
                  meta['value']
                end

    if new_value
      mail[ key.downcase.to_sym ] = if object_attribute[:data_type] == 'datetime'
                                      new_value.to_datetime
                                    else
                                      new_value.to_date
                                    end
      mail[:"#{key.downcase}-source"] = filter
    end

    true
  end
end
