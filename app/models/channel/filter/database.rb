# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

# process all database filter
module Channel::Filter::Database

  def self.run(_channel, mail)

    # process postmaster filter
    filters = PostmasterFilter.where(active: true, channel: 'email').order(:name, :created_at)
    filters.each { |filter|
      Rails.logger.info " process filter #{filter.name} ..."
      all_matches_ok = true
      min_one_rule_exists = false
      filter[:match].each { |key, meta|
        begin
          next if meta.blank? || meta['value'].blank?
          value = mail[ key.downcase.to_sym ]
          match_rule = meta['value']
          min_one_rule_exists = true
          if meta[:operator] == 'contains not'
            if value.present? && match(value, match_rule, false)
              all_matches_ok = false
              Rails.logger.info "  matching #{key.downcase}:'#{value}' on #{match_rule}, but shoud not"
            end
          elsif meta[:operator] == 'contains'
            if value.blank? || !match(value, match_rule, true)
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
      }

      next if !min_one_rule_exists
      next if !all_matches_ok

      filter[:perform].each { |key, meta|
        next if !Channel::EmailParser.check_attributes_by_x_headers(key, meta['value'])
        Rails.logger.info "  perform '#{key.downcase}' = '#{meta.inspect}'"
        mail[ key.downcase.to_sym ] = meta['value']
      }
    }

  end

  def self.match(value, match_rule, _should_match, check_mode = false)

    regexp = false
    if match_rule =~ /^(regex:)(.+?)$/
      regexp = true
      match_rule = $2
    end

    if regexp == false
      match_rule_quoted = Regexp.quote(match_rule).gsub(/\\\*/, '.*')
      return true if value =~ /#{match_rule_quoted}/i
      return false
    end

    begin
      return true if value =~ /#{match_rule}/i
      return false
    rescue => e
      message = "Can't use regex '#{match_rule}' on '#{value}': #{e.message}"
      Rails.logger.error message
      raise message if check_mode == true
    end

    false
  end

end
