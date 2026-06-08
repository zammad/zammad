# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Text::QuoteRemover::AttributionPattern::ForwardedMessage < Text::QuoteRemover::AttributionPattern
  # "Forwarded message" in common languages
  # Add more translations as needed when real-world examples appear
  # These are pattern matching strings, not UI strings - do not translate
  # rubocop:disable Zammad/DetectTranslatableString
  FORWARDED_MESSAGE = [
    'Forwarded message',          # English
    'Forwarded Message',          # English (capitalized)
    'Weitergeleitete Nachricht',  # German
    'Mensaje reenviado',          # Spanish
    'Message transféré',          # French
    'Messaggio inoltrato',        # Italian
    'Doorgestuurd bericht',       # Dutch
    'Mensagem encaminhada',       # Portuguese
    'Пересланное сообщение',      # Russian
    'Wiadomość przekazana',       # Polish
    'Přeposlaná zpráva',          # Czech
    'İletilen İleti',             # Turkish
    'Переслане повідомлення',     # Ukrainian
    'Vidarebefordrat meddelande', # Swedish
    'Videresendt melding',        # Norwegian
    'Videresendt meddelelse',     # Danish
    'Välitetty viesti',           # Finnish
    'Továbbított üzenet',         # Hungarian
    'Препратено съобщение',       # Bulgarian
    'Proslijeđena poruka',        # Croatian
    'Preposlaná správa',          # Slovak
    'Posredovano sporočilo',      # Slovenian
    'Прослеђена порука',          # Serbian
    'Mesaj redirecționat',        # Romanian
    'Persiųstas pranešimas',      # Lithuanian
    'Pārsūtīta ziņa',             # Latvian
    'Edastatud sõnum',            # Estonian
    'Áframsent skilaboð',         # Icelandic
    'Προωθημένο μήνυμα',          # Greek
  ].join('|').freeze
  # rubocop:enable Zammad/DetectTranslatableString

  def self.pattern
    # Forwarded message markers
    # Example: "---------- Forwarded message ----------"
    %r{^-{5,}\s*(#{FORWARDED_MESSAGE})\s*-{5,}}io
  end

  def self.removes_all_after?
    true
  end
end
