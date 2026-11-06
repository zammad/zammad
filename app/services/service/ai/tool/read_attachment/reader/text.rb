# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Plain text, logs, CSV, JSON, XML and HTML, read as they are: the markup of an HTML file can be what a customer asks
#   about, and its source shows the model what hides a part, where a text made of it would not.
class Service::AI::Tool::ReadAttachment::Reader::Text < Service::AI::Tool::ReadAttachment::Reader
  # A file that holds zero bytes after its conversion is binary, whatever its name says.
  NOT_TEXT = 'The file holds no text, although its type says so.'.freeze # rubocop:disable Zammad/DetectTranslatableString

  takes mime_types: %w[
    text/plain text/csv text/x-csv text/comma-separated-values text/tab-separated-values text/x-log text/log
    text/markdown text/x-markdown text/xml text/html application/csv application/json application/xml application/xhtml+xml
  ], extensions: %w[txt log csv tsv json xml md html htm xhtml]

  def read
    text = decoded_content
    return Reading.refused(NOT_TEXT) if text.include?("\u0000")

    Reading.of(AI::HiddenText.remove_characters(text))
  end
end
