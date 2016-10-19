# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Channel::Filter::Nagios < Channel::Filter::MonitoringBase
  def self.integration_name
    'nagios'
  end
end
