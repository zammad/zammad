# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

end
