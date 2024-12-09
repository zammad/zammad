# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails/generators'

class Zammad::SettingTypesGenerator < Rails::Generators::Base

  desc 'Create the types/config.ts file to keep Settings configuration the same between frontend and backend.'

  class_option :check, type: :boolean, required: false, desc: 'Only check if the types file is up-to-date.'

  SETTING_TYPES_FILEPATH = Rails.root.join 'app/frontend/shared/types/config.ts'

  def generate
    new_content = generate_types_file_content
    return file_up_to_date?(SETTING_TYPES_FILEPATH, new_content) if options['check']

    SETTING_TYPES_FILEPATH.write(new_content)
  end

  private

  def generate_types_file_content
    fields = []

    Setting.reorder(:name).each do |setting|
      if setting.frontend
        type = build_type(setting)
        fields.push("  #{setting.name}#{type}")
      end
    end

    <<~MSG
      export interface ConfigList {
        api_path: string
        'active_storage.web_image_content_types': string[]
        'auth_saml_credentials.display_name'?: string
      #{fields.join("\n")}
        [key: string]: unknown
      }
    MSG
  end

  # rubocop:disable Rails/Output
  def file_up_to_date?(filepath, new_content)
    original_file_content = filepath.read
    if original_file_content.eql? new_content
      puts "File #{filepath} is up-to-date."
    else
      warn "File #{filepath} is not up-to-date, please run 'rails generate zammad:setting_types' to update it."
      exit! # rubocop:disable Rails/Exit
    end
  end
  # rubocop:enable Rails/Output

  def build_select_type(optional:, nullable:, options:, multiple:)
    values = options.keys.map { |val| val.is_a?(String) ? "'#{val}'" : val }.join(' | ')

    return "#{optional}: (#{values})[]#{nullable}" if multiple

    "#{optional}: #{values}#{nullable}"
  end

  def build_form_type(option)
    optional = option[:null] ? '?' : ''
    nullable = option[:null] ? ' | null' : ''

    tag = option[:tag]
    options = option[:options]

    return "#{optional}: boolean#{nullable}" if tag == 'boolean' && options.key?(true)
    return "#{optional}: string#{nullable}" if tag == 'input'

    if tag == 'select'
      return build_select_type(optional: optional, nullable: nullable, options: options, multiple: option[:multiple])
    end

    nil
  end

  def build_type(setting)
    form = setting.options[:form]
    if !form.nil? && form.length == 1
      type = build_form_type(form[0])
      return type if !type.nil?
    end

    initial = setting[:state_initial][:value]
    return ': boolean' if initial.in? [true, false]
    return ': string' if initial.is_a?(String)
    return ': number' if initial.is_a?(Numeric)

    ': unknown'
  end
end
