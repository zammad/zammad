# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ScriptHelper
  def has_ipv6?
    File.exist?('/proc/net/if_inet6') && system('ip -6 addr | grep ::1')
  end
end

RSpec.configure do |config|
  # #extend adds setup methods for example groups (#describe / #context);
  # #include adds methods within actual examples (#it blocks)
  config.extend ScriptHelper, type: :script
end
