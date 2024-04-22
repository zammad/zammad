# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::FailedEmails < SystemReport::Plugin
  DESCRIPTION = __('Count of failed emails').freeze

  def fetch
    FailedEmail.count
  end
end
