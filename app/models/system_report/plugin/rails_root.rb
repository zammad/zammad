# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::RailsRoot < SystemReport::Plugin
  DESCRIPTION = __('Filepath to Zammad directory').freeze

  def fetch
    Rails.root.to_s
  end
end
