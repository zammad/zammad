# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Channel::Filter::CheckMk < Channel::Filter::MonitoringBase
  def self.integration_name
    'check_mk'
  end
end
