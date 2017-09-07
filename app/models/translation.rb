# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
require 'csv'

class Translation < ApplicationModel
  before_create :set_initial
  after_create  :cache_clear
  after_update  :cache_clear
  after_destroy :cache_clear

=begin

sync translations from local if exists, otherwise from online

all:

  Translation.sync

  Translation.sync(locale) # e. g. 'en-us' or 'de-de'

=end

  def self.sync(dedicated_locale = nil)
    return true if load_from_file(dedicated_locale)
    load
  end

=begin

load translations from online

all:

  Translation.load

dedicated:

  Translation.load(locale) # e. g. 'en-us' or 'de-de'

=end

  def self.load(dedicated_locale = nil)
    locals_to_sync(dedicated_locale).each { |locale|
      fetch(locale)
      load_from_file(locale)
    }
    true
  end

=begin

push translations to online

  Translation.push(locale)

=end

  def self.push(locale)

    # only push changed translations
    translations         = Translation.where(locale: locale)
    translations_to_push = []
    translations.each { |translation|
      if translation.target != translation.target_initial
        translations_to_push.push translation
      end
    }

    return true if translations_to_push.empty?

    url = 'https://i18n.zammad.com/api/v1/translations/thanks_for_your_support'

    translator_key = Setting.get('translator_key')

    result = UserAgent.post(
      url,
      {
        locale: locale,
        translations: translations_to_push,
        fqdn: Setting.get('fqdn'),
        translator_key: translator_key,
      },
      {
        json: true,
        open_timeout: 6,
        read_timeout: 16,
      }
    )
    raise "Can't push translations to #{url}: #{result.error}" if !result.success?

    # set new translator_key if given
    if result.data['translator_key']
      translator_key = Setting.set('translator_key', result.data['translator_key'])
    end

    true
  end

=begin

reset translations to origin

  Translation.reset(locale)

=end

  def self.reset(locale)

    # only push changed translations
    translations = Translation.where(locale: locale)
    translations.each { |translation|
      if !translation.target_initial || translation.target_initial.empty?
        translation.destroy
      elsif translation.target != translation.target_initial
        translation.target = translation.target_initial
        translation.save
      end
    }

    true
  end

=begin

get list of translations

  list = Translation.lang('de-de')

=end

  def self.lang(locale, admin = false)

    # use cache if not admin page is requested
    if !admin
      data = cache_get(locale)
      return data if data
    end

    # show total translations as reference count
    data = {
      'total' => Translation.where(locale: 'de-de').count,
    }
    list = []
    translations = if admin
                     Translation.where(locale: locale.downcase).order(:source)
                   else
                     Translation.where(locale: locale.downcase).where.not(target: '').order(:source)
                   end
    translations.each { |item|
      translation_item = []
      translation_item = if admin
                           [
                             item.id,
                             item.source,
                             item.target,
                             item.target_initial,
                             item.format,
                           ]
                         else
                           [
                             item.id,
                             item.source,
                             item.target,
                             item.format,
                           ]
                         end
      list.push translation_item
    }

    # add presorted on top
    presorted_list = []
    %w(yes no or Year Years Month Months Day Days Hour Hours Minute Minutes Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec January February March April May June July August September October November December Mon Tue Wed Thu Fri Sat Sun Monday Tuesday Wednesday Thursday Friday Saturday Sunday).each { |presort|
      list.each { |item|
        next if item[1] != presort
        presorted_list.push item
        list.delete item
        #list.unshift presort
      }
    }
    data['list'] = presorted_list.concat list

    # set cache
    if !admin
      cache_set(locale, data)
    end

    data
  end

=begin

translate strings in ruby context, e. g. for notifications

  translated = Translation.translate('de-de', 'New')

=end

  def self.translate(locale, string)

    # translate string
    records = Translation.where(locale: locale, source: string)
    records.each { |record|
      return record.target if record.source == string
    }

    # fallback lookup in en
    records = Translation.where(locale: 'en', source: string)
    records.each { |record|
      return record.target if record.source == string
    }

    string
  end

=begin

load translations from local

all:

  Translation.load_from_file

  or

  Translation.load_from_file(locale) # e. g. 'en-us' or 'de-de'

=end

  def self.load_from_file(dedicated_locale = nil)
    version = Version.get
    directory = Rails.root.join('config/translations')
    locals_to_sync(dedicated_locale).each { |locale|
      file = Rails.root.join("#{directory}/#{locale}-#{version}.yml")
      return false if !File.exist?(file)
      data = YAML.load_file(file)
      to_database(locale, data)
    }
    true
  end

=begin

fetch translation from remote and store them in local file system

all:

  Translation.fetch

  or

  Translation.fetch(locale) # e. g. 'en-us' or 'de-de'

=end

  def self.fetch(dedicated_locale = nil)
    version = Version.get
    locals_to_sync(dedicated_locale).each { |locale|
      url = "https://i18n.zammad.com/api/v1/translations/#{locale}"
      if !UserInfo.current_user_id
        UserInfo.current_user_id = 1
      end
      result = UserAgent.get(
        url,
        {
          version: version,
        },
        {
          json: true,
          open_timeout: 8,
          read_timeout: 24,
        }
      )
      raise "Can't load translations from #{url}: #{result.error}" if !result.success?

      directory = Rails.root.join('config/translations')
      if !File.directory?(directory)
        Dir.mkdir(directory, 0o755)
      end
      file = Rails.root.join("#{directory}/#{locale}-#{version}.yml")
      File.open(file, 'w') do |out|
        YAML.dump(result.data, out)
      end
    }
    true
  end

=begin

load translations from csv file

all:

  Translation.load_from_csv

  or

  Translation.load_from_csv(locale, file_location, file_charset) # e. g. 'en-us' or 'de-de' and /path/to/translation_list.csv

  e. g.

  Translation.load_from_csv('he-il', '/Users/me/Downloads/Hebrew_translation_list-1.csv', 'Windows-1255')

Get source file at https://i18n.zammad.com/api/v1/translations_empty_translation_list

=end

  def self.load_from_csv(locale_name, location, charset = 'UTF8')
    locale = Locale.find_by(locale: locale_name)
    if !locale
      raise "No such locale: #{locale_name}"
    end

    if !::File.exist?(location)
      raise "No such file: #{location}"
    end

    content = ::File.open(location, "r:#{charset}").read
    params = {
      col_sep: ',',
    }
    rows = ::CSV.parse(content, params)
    header = rows.shift

    translation_raw = []
    rows.each { |row|
      raise "Can't import translation, source is missing" if row[0].blank?
      if row[1].blank?
        warn "Skipped #{row[0]}, because translation is blank"
        next
      end
      raise "Can't import translation, format is missing" if row[2].blank?
      raise "Can't import translation, format is invalid (#{row[2]})" if row[2] !~ /^(time|string)$/
      item = {
        'locale'         => locale.locale,
        'source'         => row[0],
        'target'         => row[1],
        'target_initial' => '',
        'format'         => row[2],
      }
      translation_raw.push item
    }
    to_database(locale.name, translation_raw)
    true
  end

  private_class_method def self.to_database(locale, data)
    translations = Translation.where(locale: locale).all
    ActiveRecord::Base.transaction do
      data.each { |translation_raw|

        # handle case insensitive sql
        translation = nil
        translations.each { |item|
          next if item.format != translation_raw['format']
          next if item.source != translation_raw['source']
          translation = item
          break
        }
        if translation

          # verify if update is needed
          update_needed = false
          translation_raw.each { |key, _value|

            # if translation target has changes
            next unless translation_raw[key] != translation.target

            # do not update translations which are already changed by user
            if translation.target == translation.target_initial
              update_needed = true
              break
            end
          }
          if update_needed
            translation.update_attributes(translation_raw.symbolize_keys!)
            translation.save
          end
        else
          if !UserInfo.current_user_id
            translation_raw['updated_by_id'] = 1
            translation_raw['created_by_id'] = 1
          end
          Translation.create(translation_raw.symbolize_keys!)
        end
      }
    end
  end

  private_class_method def self.locals_to_sync(dedicated_locale = nil)
    locales_list = []
    if !dedicated_locale
      locales = Locale.to_sync
      locales.each { |locale|
        locales_list.push locale.locale
      }
    else
      locales_list = [dedicated_locale]
    end
    locales_list
  end

  private

  def set_initial
    return true if target_initial
    return true if target_initial == ''
    self.target_initial = target
    true
  end

  def cache_clear
    Cache.delete('TranslationMapOnlyContent::' + locale.downcase)
    true
  end

  def self.cache_set(locale, data)
    Cache.write('TranslationMapOnlyContent::' + locale.downcase, data)
  end
  private_class_method :cache_set

  def self.cache_get(locale)
    Cache.get('TranslationMapOnlyContent::' + locale.downcase)
  end
  private_class_method :cache_get
end
