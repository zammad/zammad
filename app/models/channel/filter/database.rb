# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

# process all database filter
module Channel::Filter::Database

  def self.run(_channel, mail)

    # process postmaster filter
    filters = PostmasterFilter.where(active: true, channel: 'email').order(:name, :created_at)
    filters.each do |filter|
      Rails.logger.info " process filter #{filter.name} ..."
      all_matches_ok = true
      min_one_rule_exists = false
      filter[:match].each do |key, meta|
        begin
          next if meta.blank? || meta['value'].blank?
          value = mail[ key.downcase.to_sym ]
          match_rule = meta['value']
          min_one_rule_exists = true
          if meta[:operator] == 'contains not'
            if value.present? && Channel::Filter::Match::EmailRegex.match(value: value, match_rule: match_rule)
              all_matches_ok = false
              Rails.logger.info "  matching #{key.downcase}:'#{value}' on #{match_rule}, but shoud not"
            end
          elsif meta[:operator] == 'contains'
            if value.blank? || !Channel::Filter::Match::EmailRegex.match(value: value, match_rule: match_rule)
              all_matches_ok = false
              Rails.logger.info "  not matching #{key.downcase}:'#{value}' on #{match_rule}, but should"
            end
          else
            all_matches_ok = false
            Rails.logger.info "  Invalid operator in match #{meta.inspect}"
          end
          break if !all_matches_ok
        rescue => e
          all_matches_ok = false
          Rails.logger.error "can't use match rule #{match_rule} on #{value}"
          Rails.logger.error e.inspect
        end
      end

      next if !min_one_rule_exists
      next if !all_matches_ok

      filter[:perform].each do |key, meta|
        next if !Channel::EmailParser.check_attributes_by_x_headers(key, meta['value'])
        Rails.logger.info "  perform '#{key.downcase}' = '#{meta.inspect}'"

        if key.downcase == 'x-zammad-ticket-tags' && meta['value'].present? && meta['operator'].present?
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
