# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# process all database filter
module Channel::Filter::Database

  def self.run(_channel, mail, _transaction_params)

    # process postmaster filter
    filters = PostmasterFilter.where(active: true, channel: 'email').order(:name, :created_at)
    filters.each do |filter|
      Rails.logger.debug { " process filter #{filter.name} ..." }
      all_matches_ok = true
      min_one_rule_exists = false
      filter[:match].each do |key, meta|

        next if meta.blank? || meta['value'].blank?

        value = mail[ key.downcase.to_sym ]
        match_rule = meta['value']
        min_one_rule_exists = true
        case meta[:operator]
        when 'contains not'
          if value.present? && Channel::Filter::Match::EmailRegex.match(value: value, match_rule: match_rule)
            all_matches_ok = false
            Rails.logger.debug { "  not matching content '#{key.downcase}' contains not #{match_rule}" }
          else
            Rails.logger.info { "  matching: content '#{key.downcase}' contains not #{match_rule}" }
          end
        when 'contains'
          if value.blank? || !Channel::Filter::Match::EmailRegex.match(value: value, match_rule: match_rule)
            all_matches_ok = false
            Rails.logger.debug { "  not matching content '#{key.downcase}' contains #{match_rule}" }
          else
            Rails.logger.info { "  matching content '#{key.downcase}' contains #{match_rule}" }
          end
        else
          all_matches_ok = false
          Rails.logger.info { "  Invalid operator in match #{meta.inspect}" }
        end
        break if !all_matches_ok
      rescue => e
        all_matches_ok = false
        Rails.logger.error "can't use match rule #{match_rule} on #{value}"
        Rails.logger.error e.inspect

      end

      next if !min_one_rule_exists
      next if !all_matches_ok

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
            end
          when 'remove'
            tags.each do |tag|
              next if tag.blank?

              tag.strip!
              mail[ 'x-zammad-ticket-tags'.downcase.to_sym ] -= [tag]
            end
          end
          next
        end

        mail[ key.downcase.to_sym ] = meta['value']
      end
    end

  end

end
