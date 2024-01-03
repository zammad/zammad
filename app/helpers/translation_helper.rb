# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module TranslationHelper
  def zammad_translate(string, *)
    Translation.translate(system_locale_via_uri&.locale, string, *)
  end

  alias zt zammad_translate
end
