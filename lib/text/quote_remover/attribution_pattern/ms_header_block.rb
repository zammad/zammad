# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Text::QuoteRemover::AttributionPattern::MsHeaderBlock < Text::QuoteRemover::AttributionPattern
  # Microsoft Outlook style header block detection
  # Requires two consecutive lines: "From:" followed by another header like "Sent:" or "To:"
  #
  # Example:
  #   Von: John Doe <john@example.com>
  #   Gesendet: Montag, 1. Dezember 2025 10:00

  # "From" in various languages (27 languages)
  # rubocop:disable Zammad/DetectTranslatableString
  FROM_LABELS = [
    'From', 'Von', 'De', 'От', 'Z', 'Od', 'Ze', 'Fra', 'Van', 'Mistä',
    'Από', 'Dal', 'から', 'Из', 'од', 'iz', 'Från', 'จาก', 'з', 'Từ',
    'Feladó', 'Nuo', 'No', 'Saatja', 'Frá', 'De la',
  ].join('|').freeze
  # rubocop:enable Zammad/DetectTranslatableString

  # Common email header labels that follow "From:" (To/Sent/Date/Subject)
  HEADER_LABELS = %w[
    To Sent Date Subject Cc Bcc
    An Gesendet Datum Betreff
    Para Enviado Fecha Asunto
    À Envoyé Objet
    Per Inviato Data Oggetto
    Aan Verzonden Onderwerp
    Till Skickat Ämne
    Til Sendt Dato Emne
    Vastaanottaja Lähetetty Päivämäärä Aihe
    Címzett Elküldve Dátum Tárgy
    До Изпратено Дата Тема
    Prima Trimis Subiect
    Komu Odesláno Předmět
    Kime Gönderildi Tarih Konu
    Кому Надіслано Тема
  ].join('|').freeze

  FROM_PATTERN = %r{^(#{FROM_LABELS})( ?):}i
  HEADER_PATTERN = %r{^(#{HEADER_LABELS})( ?):}i

  # This pattern requires context (two lines), so single-line pattern returns nil
  def self.pattern
    nil
  end

  # Single line matching not supported for this pattern
  def self.match?(_line)
    false
  end

  # Check if lines at given index form a Microsoft header block
  def self.match_at?(lines, index)
    return false if index + 1 >= lines.length

    current_line = lines[index].strip
    next_line = lines[index + 1].strip

    current_line.match?(FROM_PATTERN) && next_line.match?(HEADER_PATTERN)
  end
end
