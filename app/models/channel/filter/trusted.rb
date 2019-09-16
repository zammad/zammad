# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

# delete all X-Zammad header if channel is not trusted
module Channel::Filter::Trusted

  def self.run(channel, mail)

    # check if trust x-headers
    if !channel[:trusted]
      mail.each_key do |key|
        next if !key.match?(/^x-zammad/i)

        mail.delete(key)
      end
      return
    end

    # verify values
    mail.each do |key, value|
      next if !key.match?(/^x-zammad/i)

      # no assoc exists, remove header
      next if Channel::EmailParser.check_attributes_by_x_headers(key, value)

      mail.delete(key.to_sym)
    end

  end
end
