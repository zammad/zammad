# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::Channel < SystemReport::Plugin
  DESCRIPTION = __('Lists active channels (e.g. 1 Telegram channel, 2 Microsoft channels and 1 Google channel)').freeze

  def fetch
    ::Channel.where(active: true).map(&:area).tally
  end
end
