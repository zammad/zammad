# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Channel::Filter::CheckMk < Channel::Filter::MonitoringBase
  def self.integration_name
    'check_mk'
  end
end
