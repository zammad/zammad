# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Text::QuoteRemover::AttributionPattern::MsOriginalMessage < Text::QuoteRemover::AttributionPattern
  # "Original Message" and "Original Appointment" in common languages
  # Add more translations as needed when real-world examples appear
  # These are pattern matching strings, not UI strings - do not translate
  # rubocop:disable Zammad/DetectTranslatableString
  ORIGINAL_MESSAGE = [
    'Original Message',           # English
    'Original Appointment',       # English (calendar)
    'Ursprüngliche Nachricht',    # German
    'Ursprünglicher Termin',      # German (calendar)
    'Mensaje original',           # Spanish
    'Cita original',              # Spanish (calendar)
    "Message d'origine",          # French
    "Rendez-vous d'origine",      # French (calendar)
    'Messaggio originale',        # Italian
    'Appuntamento originale',     # Italian (calendar)
    'Oorspronkelijk bericht',     # Dutch
    'Oorspronkelijke afspraak',   # Dutch (calendar)
    'Mensagem original',          # Portuguese
    'Compromisso original',       # Portuguese (calendar)
    'Исходное сообщение',         # Russian
    'Oryginalna wiadomość',       # Polish
    'Původní zpráva',             # Czech
    'Özgün İleti',                # Turkish
    'Оригінальне повідомлення',   # Ukrainian
    'Ursprungligt meddelande',    # Swedish
    'Opprinnelig melding',        # Norwegian
    'Oprindelig meddelelse',      # Danish
    'Alkuperäinen viesti',        # Finnish
    'Eredeti üzenet',             # Hungarian
    'Оригинално съобщение',       # Bulgarian
    'Izvorna poruka',             # Croatian
    'Pôvodná správa',             # Slovak
    'Izvirno sporočilo',          # Slovenian
    'Оригинална порука',          # Serbian
    'Mesaj original',             # Romanian
    'Originalus pranešimas',      # Lithuanian
    'Sākotnējais ziņojums',       # Latvian
    'Algne sõnum',                # Estonian
    'Upprunalegt skilaboð',       # Icelandic
    'Αρχικό μήνυμα',              # Greek
    '邮件原件',                    # Chinese Simplified
    '原始郵件',                    # Chinese Traditional
  ].join('|').freeze
  # rubocop:enable Zammad/DetectTranslatableString

  def self.pattern
    # Example: "-----Original Message-----" or "-------- Original Message --------"
    # Also: "-----Ursprünglicher Termin-----" for calendar appointments
    # Some clients use 5 dashes, others use more
    %r{-{4,}\s*(#{ORIGINAL_MESSAGE})\s*-{4,}}io
  end

  def self.removes_all_after?
    true
  end
end
