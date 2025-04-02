# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class LanguageDetectionHelper

=begin

Detect language based on text

  LanguageDetectionHelper.detect('Entdecken Sie jetzt das Zammad Ticketsystem!')

returns

  Language code of the detected text

=end

  def self.detect(text)
    result = CLD.detect_language(text)

    return if !result[:reliable] || result[:code] == 'un' # unknown

    return if display_value(result[:code]).blank?

    result[:code]
  end

=begin

Returns the language name

  LanguageDetectionHelper.display_value('de')

returns

  German

=end

  def self.display_value(code)
    attribute = ObjectManager::Attribute.for_object('TicketArticle').find_by(name: 'detected_language')
    attribute.data_option[:options][code]
  end
end
