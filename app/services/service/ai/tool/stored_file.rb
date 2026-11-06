# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# What a stored file says of itself, as a mail part or an upload stored it: its type and its charset.
class Service::AI::Tool::StoredFile
  # @param file [Store]
  # @return [String] the type the file was stored with, without its parameters, empty where it has none
  def self.mime_type(file)
    content_type(file).split(';').first.to_s.strip.downcase
  end

  # @param file [Store]
  # @return [String, nil] the charset the file was stored with
  def self.charset(file)
    file.preferences['Charset'].presence || content_type(file)[%r{charset="?([^";\s]+)}i, 1]
  end

  def self.content_type(file)
    (file.preferences['Content-Type'].presence || file.preferences['Mime-Type']).to_s
  end
  private_class_method :content_type
end
