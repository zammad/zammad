# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

# process all database filter
module Channel::Filter::Database

  def self.run( _channel, mail )

    # process postmaster filter
    filters = PostmasterFilter.where( active: true, channel: 'email' ).order(:name, :created_at)
    filters.each { |filter|
      Rails.logger.info " proccess filter #{filter.name} ..."
      all_matches_ok = true
      min_one_rule_exists = false
      filter[:match].each { |key, meta|
        begin
          next if !meta || !meta['value'] || meta['value'].empty?
          min_one_rule_exists = true
          scan = []
          if mail
            scan = mail[ key.downcase.to_sym ].scan(/#{meta['value']}/i)
          end
          if scan[0]
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
        Rails.logger.info "  perform '#{key.downcase}' = '#{meta.inspect}'"
        mail[ key.downcase.to_sym ] = meta['value']
      }
    }

  end
end
