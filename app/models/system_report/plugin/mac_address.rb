# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::MacAddress < SystemReport::Plugin
  DESCRIPTION = __('MAC address (unique identifier of the report)').freeze

  def fetch
    Mac.addr.try(:list) || Mac.addr
  end
end
