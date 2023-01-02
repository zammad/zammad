# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module TranslationHelper
  def zammad_translate(string, *args)
    Translation.translate(system_locale_via_uri&.locale, string, *args)
  end

  alias zt zammad_translate
end
