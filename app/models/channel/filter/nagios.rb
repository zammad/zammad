# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Channel::Filter::Nagios < Channel::Filter::MonitoringBase
  def self.integration_name
    'nagios'
  end
end
