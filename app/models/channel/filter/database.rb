# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# process all database filter
module Channel::Filter::Database
  def self.run(_channel, mail, _transaction_params)
    PostmasterFilter.where(active: true, channel: 'email').reorder(:name, :created_at).each do |filter|
      # The leading space is intentional to make the logs more readable.
      Rails.logger.debug { " process filter #{filter.name} ..." }
      FilterProcessor.new(filter, mail).process
    end
  end
end
