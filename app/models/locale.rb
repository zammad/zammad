# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Locale < ApplicationModel

  has_many :knowledge_base_locales, inverse_of: :system_locale, dependent: :restrict_with_error,
                                    class_name: 'KnowledgeBase::Locale', foreign_key: :system_locale_id

=begin

get locals to sync

all:

  Locale.to_sync

returns

 ['en-us', 'de-de', ...]

=end

  def self.to_sync
    locales = Locale.where(active: true)
    if Rails.env.test?
      locales = Locale.where(active: true, locale: %w[en-us de-de])
    end

    # read used locales based on env, e. g. export Z_LOCALES='en-us:de-de'
    if ENV['Z_LOCALES']
      locales = Locale.where(active: true, locale: ENV['Z_LOCALES'].split(':'))
    end
    locales
  end

=begin

sync locales from local if exists, otherwise from online

all:

  Locale.sync

=end

  def self.sync
    return true if load_from_file

    load
  end

=begin

load locales from online

all:

  Locale.load

=end

  def self.load
    data = fetch
    to_database(data)
  end

=begin

load locales from local

all:

  Locale.load_from_file

=end

  def self.load_from_file
    version = Version.get
    file = Rails.root.join('config', "locales-#{version}.yml")
    return false if !File.exist?(file)

    data = YAML.load_file(file)
    to_database(data)
    true
  end

=begin

fetch locales from remote and store them in local file system

all:

  Locale.fetch

=end

  def self.fetch
    version = Version.get
    url = 'https://i18n.zammad.com/api/v1/locales'

    result = UserAgent.get(
      url,
      {
        version: version,
      },
      {
        json:         true,
        open_timeout: 8,
        read_timeout: 24,
      }
    )

    raise "Can't load locales from #{url}" if !result
    raise "Can't load locales from #{url}: #{result.error}" if !result.success?

    file = Rails.root.join('config', "locales-#{version}.yml")
    File.open(file, 'w') do |out|
      YAML.dump(result.data, out)
    end
    result.data
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
