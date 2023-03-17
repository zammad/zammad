# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::Extractor::ViewTemplates < Zammad::TranslationCatalog::Extractor::Base

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
    extracted_strings << Zammad::TranslationCatalog::ExtractedString.new(string: string, comment: comment, references: [filename], skip_translation_sync: true)
  end

  def find_files
    files = []
    %w[mailer slack].each do |dir|
      files += Dir.glob("#{base_path}/app/views/#{dir}/*/en.*.erb")
    end
    files
  end
end
