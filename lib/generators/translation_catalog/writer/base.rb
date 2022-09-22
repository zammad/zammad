# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Generators::TranslationCatalog::Writer::Base
  attr_reader :options

  def initialize(options:)
    @options = options
  end

  protected

  def base_path
    options['addon_path'] || Rails.root.to_s
  end

  def target_path
    FileUtils.mkdir_p("#{base_path}/i18n")
    "#{base_path}/i18n/#{product_name.downcase}"
  end

  def product_name
    return 'zammad' if !options['addon_path']

    File.basename options['addon_path']
  end

  def escape_for_js(string)
    string.gsub(%r{\\}) { '\\\\' }.gsub(%r{'}) { "\\'" }
  end

end
