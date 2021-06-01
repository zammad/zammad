# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# delete all X-Zammad header if channel is not trusted
module Channel::Filter::Trusted

  def self.run(channel, mail, _transaction_params)

    # check if trust x-headers
    if !trusted(channel)
      mail.each_key do |key|
        next if !key.match?(%r{^x-zammad}i)

        mail.delete(key)
      end
      return
    end

    # verify values
    mail.each do |key, value|
      next if !key.match?(%r{^x-zammad}i)

      # no assoc exists, remove header
      next if Channel::EmailParser.check_attributes_by_x_headers(key, value)

      mail.delete(key.to_sym)
    end

  end

  def self.trusted(channel)
    return true if channel[:trusted]
    return true if channel.instance_of?(Channel) && channel.options[:inbound] && channel.options[:inbound][:trusted]

    false
  end
end
