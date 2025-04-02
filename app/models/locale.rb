# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Locale < ApplicationModel
  has_many :knowledge_base_locales, inverse_of: :system_locale, dependent: :restrict_with_error,
                                    class_name: 'KnowledgeBase::Locale', foreign_key: :system_locale_id

=begin

returns the records of all locales that are to be synchronized

=end

  def self.to_sync
    # read used locales based on env, e. g. export Z_LOCALES='en-us:de-de'
    return Locale.where(active: true, locale: ENV['Z_LOCALES'].split(':')) if ENV['Z_LOCALES']

    return Locale.where(active: true, locale: %w[en-us de-de]) if Rails.env.test?

    Locale.where(active: true)
  end

=begin

sync locales from config/locales.yml

=end

  def self.sync
    file = Rails.root.join('config/locales.yml')
    return false if !File.exist?(file)

    data = YAML.load_file(file)
    to_database(data)
    true
  end

  #  Default system locale
  #
  #  @example
  #    Locale.default
  def self.default
    Setting.get('locale_default') || 'en-us'
  end

  private_class_method def self.to_database(data)
    ActiveRecord::Base.transaction do
      data.each do |locale|
        exists = Locale.find_by(locale: locale['locale'])
        if exists
          exists.update!(locale.symbolize_keys!)
        else
          Locale.create!(locale.symbolize_keys!)
        end
      end
    end
  end

  # Returns ICU language code for usage with TwitterCldr gem
  # Not all locales are supported, so nil can be returned as well!
  #
  # One-liner to filter which locales are not supported by said gem:
  #
  # Locale.all.select { |locale| !TwitterCldr.supported_locale? locale.language_code }
  def cldr_language_code
    case locale
    when 'es-ca' # Catalin, looks like it should be ca-es instead?
      'ca'
    when 'sr-cyrl-rs'
      'sr-Cyrl-ME'
    when 'sr-latn-rs'
      'sr-Latn-ME'
    else
      split = locale.split('-')
      split.second&.upcase!
      joined = split.join('-')

      if TwitterCldr.supported_locale? joined
        joined
      elsif TwitterCldr.supported_locale? split.first
        split.first
      end
    end
  end

  # Returns Postgres database collation names
  #
  # One-liner to verify that locales exist on a given Postgres server:
  #
  # Locale.all.select { |locale| ApplicationModel.connection.execute("SELECT * FROM pg_collation WHERE collname = '#{locale.postgres_collation_name}';").none? }
  def postgres_collation_name
    case locale
    when 'es-ca' # Catalan, looks like it should be ca-es instead?
      'ca-x-icu'
    when 'no-no' # Norwegian, nn vs no?
      'nn-NO-x-icu'
    when 'zh-cn' # China uses simplified
      'zh-Hans-x-icu'
    when 'zh-tw' # Taiwan uses traditional
      'zh-Hant-x-icu'
    when 'sr-cyrl-rs'
      'sr-Cyrl-ME-x-icu'
    when 'sr-latn-rs'
      'sr-Latn-ME-x-icu'
    else
      split = locale.split('-')
      split.second&.upcase!
      "#{split.join('-')}-x-icu"
    end
  end
end
