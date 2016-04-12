# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Channel::Filter::Nagios < Channel::Filter::MonitoringBase
  # rubocop:disable Style/ClassVars
  @@integration = 'nagios'
  # rubocop:enable Style/ClassVars
end
