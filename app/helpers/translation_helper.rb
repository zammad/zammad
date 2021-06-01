# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module TranslationHelper
  def zammad_translate(string)
    Translation.translate(system_locale_via_uri&.locale, string)
  end

  alias zt zammad_translate
end
