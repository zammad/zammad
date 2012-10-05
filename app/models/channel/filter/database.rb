# process all database filter
module Channel::Filter::Database

  def self.run( channel, mail )

    # process postmaster filter
    filters = [
      {
        :name  => 'some name',
        :match => {
          'from' => 'martin',
        },
        :set => {
          'x-zammad-priority' => '3 high',
        }
      },
    ]

    filters.each {|filter|
      match = true
      filter[:match].each {|key, value|
        begin
          if match && mail[ key.to_sym ].scan(/#{value}/i)
            match = true
          else
            match = false
          end
        rescue Exception => e
          match = false
          puts "can't use match rule #{value} on #{mail[ key.to_sym ]}"
          puts e.inspect
        end
      }
      if match
        filter[:set].each {|key, value|
          mail[ key.to_sym ] = value
        }
      end
    }

  end
end