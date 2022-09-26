# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Generators::TranslationCatalog::Extractor::ViewTemplates < Generators::TranslationCatalog::Extractor::Base

  EXTENSION_TO_FORMAT_TYPE = {
    'md'   => 'Markdown',
    'txt'  => 'Text',
    'html' => 'HTML',
  }.freeze

  def extract_from_string(string, filename)
    format_type = EXTENSION_TO_FORMAT_TYPE[filename.split('.')[-2]] # en.html.erb
    comment = <<~COMMENT
      This is the template file #{filename} in ERB/#{format_type} format.
      Please make sure to translate it to a valid corresponding output structure.
    COMMENT
    strings << Generators::TranslationCatalog::ExtractedString.new(string: string, comment: comment, references: [filename], skip_translation_sync: true)
  end

  def find_files(base_path)
    files = []
    %w[mailer slack].each do |dir|
      files += Dir.glob("#{base_path}/app/views/#{dir}/*/en.*.erb")
    end
    files
  end
end
