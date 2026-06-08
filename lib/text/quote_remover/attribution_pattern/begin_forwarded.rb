# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Text::QuoteRemover::AttributionPattern::BeginForwarded < Text::QuoteRemover::AttributionPattern
  # "Begin forwarded message" in common languages (Apple Mail style)
  # Add more translations as needed when real-world examples appear
  # These are pattern matching strings, not UI strings - do not translate
  # rubocop:disable Zammad/DetectTranslatableString
  BEGIN_FORWARDED = [
    'Begin forwarded message',                # English
    'Anfang der weitergeleiteten Nachricht',  # German
    'Inicio del mensaje reenviado',           # Spanish
    'Début du message réexpédié',             # French
    'Inizio del messaggio inoltrato',         # Italian
    'Begin doorgestuurd bericht',             # Dutch
    'Início da mensagem encaminhada',         # Portuguese
    'Начало пересылаемого сообщения',         # Russian
    'Początek przekazanej wiadomości',        # Polish
    'Začátek přeposílané zprávy',             # Czech
    'İletilen iletinin başlangıcı',           # Turkish
    'Початок пересланого повідомлення',       # Ukrainian
    'Vidarebefordrat meddelande börjar',      # Swedish
    'Begynnelse på videresendt melding',      # Norwegian
    'Videresendt meddelelse starter',         # Danish
    'Välitetyn viestin alku',                 # Finnish
    'Továbbított üzenet kezdete',             # Hungarian
    'Начало на препратено съобщение',         # Bulgarian
    'Početak proslijeđene poruke',            # Croatian
    'Začiatok preposlanej správy',            # Slovak
    'Začetek posredovanega sporočila',        # Slovenian
    'Почетак прослеђене поруке',              # Serbian
    'Începutul mesajului redirecționat',      # Romanian
    'Persiųsto pranešimo pradžia',            # Lithuanian
    'Pārsūtītās ziņas sākums',                # Latvian
    'Edastatud sõnumi algus',                 # Estonian
    'Upphaf áframsends skilaboðs',            # Icelandic
    'Αρχή προωθημένου μηνύματος',             # Greek
  ].join('|').freeze
  # rubocop:enable Zammad/DetectTranslatableString

  def self.pattern
    # Apple Mail forwarded message style
    # Example: "Begin forwarded message:" or "---Begin forwarded message:---"
    %r{^-{0,5}\s*(#{BEGIN_FORWARDED}):\s*-{0,5}$}io
  end

  def self.removes_all_after?
    true
  end
end
