# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

# process all database filter
module Channel::Filter::Database

  def self.run( _channel, mail )

    # process postmaster filter
    filters = PostmasterFilter.where( active: true, channel: 'email' )
    filters.each {|filter|
      Rails.logger.info " proccess filter #{filter.name} ..."
      match = true
      looped = false
      filter[:match].each {|key, value|
        looped = true
        begin
          scan = []
          if mail
            scan = mail[ key.downcase.to_sym ].scan(/#{value}/i)
          end
          if match && scan[0]
            Rails.logger.info "  matching #{ key.downcase }:'#{ mail[ key.downcase.to_sym ] }' on #{value}"
            match = true
          else
            Rails.logger.info "  is not matching #{ key.downcase }:'#{ mail[ key.downcase.to_sym ] }' on #{value}"
            match = false
          end
        rescue => e
          match = false
          Rails.logger.error "can't use match rule #{value} on #{mail[ key.to_sym ]}"
          Rails.logger.error e.inspect
        end
      }

      next if !looped
      next if !match

      filter[:perform].each {|key, value|
        Rails.logger.info "  perform '#{ key.downcase }' = '#{value}'"
        mail[ key.downcase.to_sym ] = value
      }
    }

  end
end
