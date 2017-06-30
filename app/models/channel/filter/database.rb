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
          min_one_rule_exists = true
          has_matched = false
          if mail[ key.downcase.to_sym ].present? && mail[ key.downcase.to_sym ] =~ /#{meta['value']}/i
            has_matched = true
          end
          if has_matched
            if meta[:operator] == 'contains not'
              all_matches_ok = false
            end
            Rails.logger.info "  matching #{key.downcase}:'#{mail[ key.downcase.to_sym ]}' on #{meta['value']}"
          else
            if meta[:operator] == 'contains'
              all_matches_ok = false
            end
            Rails.logger.info "  not matching #{key.downcase}:'#{mail[ key.downcase.to_sym ]}' on #{meta['value']}"
          end
          break if !all_matches_ok
        rescue => e
          all_matches_ok = false
          Rails.logger.error "can't use match rule #{meta['value']} on #{mail[ key.to_sym ]}"
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
end
