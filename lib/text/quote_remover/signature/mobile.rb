# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Text::QuoteRemover::Signature::Mobile < Text::QuoteRemover::Signature
  # Mobile device signatures like "Sent from my iPhone"

  PATTERNS = [
    # Chinese
    %r{^[[:blank:]]*從我的 iPhone 傳送}i,

    # English
    %r{^[[:blank:]]*[[:word:]]+ from mobile}i,
    %r{^[[:blank:]]*[(<]*Sent (from|via|with|by) .+[)>]*}i,
    %r{^[[:blank:]]*From my .{1,20}}i,
    %r{^[[:blank:]]*Get Outlook for }i,

    # French
    %r{^[[:blank:]]*Envoyé depuis (mon|Yahoo Mail)}i,

    # German
    %r{^[[:blank:]]*Von meinem .+ gesendet}i,
    %r{^[[:blank:]]*Diese Nachricht wurde von .+ gesendet}i,

    # Italian
    %r{^[[:blank:]]*Inviato da }i,

    # Norwegian
    %r{^[[:blank:]]*Sendt fra min }i,

    # Portuguese
    %r{^[[:blank:]]*Enviado do meu }i,

    # Spanish
    %r{^[[:blank:]]*Enviado desde mi }i,

    # Dutch
    %r{^[[:blank:]]*Verzonden (met|vanaf) }i,
    %r{^[[:blank:]]*Verstuurd vanaf mijn }i,

    # Swedish
    %r{^[[:blank:]]*Skickat från min }i,
    %r{^[[:blank:]]*från min }i,

    # Russian
    %r{^[[:blank:]]*Отправлено с }i,

    # Polish
    %r{^[[:blank:]]*Wysłane z }i,
  ].freeze

  def self.match?(line)
    PATTERNS.any? { |pattern| line.match?(pattern) }
  end
end
