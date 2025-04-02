# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::Version < SystemReport::Plugin
  DESCRIPTION = __('Zammad version').freeze

  def fetch
    ::Version.get
  end
end
