# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# process all database filter
module Channel::Filter::Database

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

      if !rule_matches?(meta[:operator], match_rule, value)
        Rails.logger.debug { "  not matching content '#{key.downcase}' contains not #{match_rule}" }
        return false
      end

      Rails.logger.info { "  matching: content '#{key.downcase}' contains not #{match_rule}" }
    rescue => e
      Rails.logger.error "can't use match rule #{match_rule} on #{value}"
      Rails.logger.error e.inspect
      return false
    end

    min_one_rule_exists
  end

  def self.rule_matches?(operator, match_rule, value)
    case operator
    when 'contains not'
      value.blank? || !Channel::Filter::Match::EmailRegex.match(value: value, match_rule: match_rule)
    when 'contains'
      value.present? && Channel::Filter::Match::EmailRegex.match(value: value, match_rule: match_rule)
    when 'is'
      value == match_rule
    when 'is not'
      value != match_rule
    when 'starts with'
      value.downcase.start_with? match_rule.downcase
    when 'ends with'
      value.downcase.end_with? match_rule.downcase
    else
      Rails.logger.info { "  Invalid operator in match #{meta.inspect}" }
      false
    end
  end

  def self.perform_filter_changes(mail, filter)
    filter[:perform].each do |key, meta|
      next if !Channel::EmailParser.check_attributes_by_x_headers(key, meta['value'])

      Rails.logger.debug { "  perform '#{key.downcase}' = '#{meta.inspect}'" }

      if key.casecmp('x-zammad-ticket-tags').zero? && meta['value'].present? && meta['operator'].present?
        mail[ 'x-zammad-ticket-tags'.downcase.to_sym ] ||= []
        tags = meta['value'].split(',')

        case meta['operator']
        when 'add'
          tags.each do |tag|
            next if tag.blank?

            tag.strip!
            next if mail[ 'x-zammad-ticket-tags'.downcase.to_sym ].include?(tag)

            mail[ 'x-zammad-ticket-tags'.downcase.to_sym ].push tag
            mail[:'x-zammad-ticket-tags-source'] = filter
          end
        when 'remove'
          tags.each do |tag|
            next if tag.blank?

            tag.strip!
            mail[ 'x-zammad-ticket-tags'.downcase.to_sym ] -= [tag]
            mail[:'x-zammad-ticket-tags-source'] = filter
          end
        end
        next
      end

      next if perform_filter_changes_date(mail: mail, filter: filter, key: key, meta: meta)

      mail[ key.downcase.to_sym ] = meta['value']
      mail[:"#{key.downcase}-source"] = filter
    end
  end

  def self.perform_filter_changes_date(mail:, filter:, key:, meta:)
    return if key !~ %r{x-zammad-ticket-(.*)}

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
