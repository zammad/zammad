# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module KnowledgeBaseHumanDateHelper
  def human_time_tag(time, locale: system_locale_via_uri)
    timezone     = Setting.get('timezone_default_sanitized')
    time_in_zone = time.in_time_zone(timezone)
    locale_name  = locale.locale

    time_tag time, title: time_in_zone do
      Translation.timestamp(locale_name, timezone, time_in_zone, append_timezone: false)
    end
  end
end
