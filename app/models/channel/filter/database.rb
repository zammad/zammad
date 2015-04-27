# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

# process all database filter
module Channel::Filter::Database

  def self.run( channel, mail )

    # process postmaster filter
    filters = PostmasterFilter.where( active: true, channel: 'email' )
    filters.each {|filter|
      puts " proccess filter #{filter.name} ..."
      match = true
      loop = false
      filter[:match].each {|key, value|
        loop = true
        begin
          scan = []
          if mail
            scan = mail[ key.downcase.to_sym ].scan(/#{value}/i)
          end
          if match && scan[0]
            puts "  matching #{ key.downcase }:'#{ mail[ key.downcase.to_sym ] }' on #{value}"
            match = true
          else
            puts "  is not matching #{ key.downcase }:'#{ mail[ key.downcase.to_sym ] }' on #{value}"
            match = false
          end
        rescue Exception => e
          match = false
          puts "can't use match rule #{value} on #{mail[ key.to_sym ]}"
          puts e.inspect
        end
      }
      if loop && match
        filter[:perform].each {|key, value|
          puts "  perform '#{ key.downcase }' = '#{value}'"
          mail[ key.downcase.to_sym ] = value
        }
      end
    }

  end
end
