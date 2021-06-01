# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
    locals_to_sync(dedicated_locale).each do |locale|
      fetch(locale)
      load_from_file(locale)
    end
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
    translations.each do |translation|
      if translation.target != translation.target_initial
        translations_to_push.push translation
      end
    end

    return true if translations_to_push.blank?

    url = 'https://i18n.zammad.com/api/v1/translations/thanks_for_your_support'

    translator_key = Setting.get('translator_key')

    result = UserAgent.post(
      url,
      {
        locale:         locale,
        translations:   translations_to_push,
        fqdn:           Setting.get('fqdn'),
        translator_key: translator_key,
      },
      {
        json:         true,
        open_timeout: 8,
        read_timeout: 24,
      }
    )
    raise "Can't push translations to #{url}: #{result.error}" if !result.success?

    # set new translator_key if given
    if result.data['translator_key']
      Setting.set('translator_key', result.data['translator_key'])
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
    translations.each do |translation|
      if translation.target_initial.blank?
        translation.destroy
      elsif translation.target != translation.target_initial
        translation.target = translation.target_initial
        translation.save
      end
    end

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
    translations.each do |item|
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
    end

    # add presorted on top
    presorted_list = []
    %w[yes no or Year Years Month Months Day Days Hour Hours Minute Minutes Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec January February March April May June July August September October November December Mon Tue Wed Thu Fri Sat Sun Monday Tuesday Wednesday Thursday Friday Saturday Sunday].each do |presort|
      list.each do |item|
        next if item[1] != presort

        presorted_list.push item
        list.delete item
        #list.unshift presort
      end
    end
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
    records.each do |record|
      return record.target if record.source == string
    end

    # fallback lookup in en
    records = Translation.where(locale: 'en', source: string)
    records.each do |record|
      return record.target if record.source == string
    end

    string
  end

=begin

translate timestampes in ruby context, e. g. for notifications

  translated = Translation.timestamp('de-de', 'Europe/Berlin', '2018-10-10T10:00:00Z0')

or

  translated = Translation.timestamp('de-de', 'Europe/Berlin', Time.zone.parse('2018-10-10T10:00:00Z0'))

=end

  def self.timestamp(locale, timezone, timestamp)

    if timestamp.instance_of?(String)
      begin
        timestamp_parsed = Time.zone.parse(timestamp)
        return timestamp.to_s if !timestamp_parsed

        timestamp = timestamp_parsed
      rescue
        return timestamp.to_s
      end
    end

    begin
      timestamp = timestamp.in_time_zone(timezone)
    rescue
      return timestamp.to_s
    end

    record = Translation.where(locale: locale, source: 'timestamp', format: 'time').pluck(:target).first
    return timestamp.to_s if !record

    record.sub!('dd', format('%<day>02d', day: timestamp.day))
    record.sub!('d', timestamp.day.to_s)
    record.sub!('mm', format('%<month>02d', month: timestamp.month))
    record.sub!('m', timestamp.month.to_s)
    record.sub!('yyyy', timestamp.year.to_s)
    record.sub!('yy', timestamp.year.to_s.last(2))
    record.sub!('SS', format('%<second>02d', second: timestamp.sec.to_s))
    record.sub!('MM', format('%<minute>02d', minute: timestamp.min.to_s))
    record.sub!('HH', format('%<hour>02d', hour: timestamp.hour.to_s))
    "#{record} (#{timezone})"
  end

=begin

translate date in ruby context, e. g. for notifications

  translated = Translation.date('de-de', '2018-10-10')

or

  translated = Translation.date('de-de', Date.parse('2018-10-10'))

=end

  def self.date(locale, date)

    if date.instance_of?(String)
      begin
        date_parsed = Date.parse(date)
        return date.to_s if !date_parsed

        date = date_parsed
      rescue
        return date.to_s
      end
    end

    return date.to_s if date.class != Date

    record = Translation.where(locale: locale, source: 'date', format: 'time').pluck(:target).first
    return date.to_s if !record

    record.sub!('dd', format('%<day>02d', day: date.day))
    record.sub!('d', date.day.to_s)
    record.sub!('mm', format('%<month>02d', month: date.month))
    record.sub!('m', date.month.to_s)
    record.sub!('yyyy', date.year.to_s)
    record.sub!('yy', date.year.to_s.last(2))
    record
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
    locals_to_sync(dedicated_locale).each do |locale|
      file = Rails.root.join(directory, "#{locale}-#{version}.yml")
      return false if !File.exist?(file)

      data = YAML.load_file(file)
      to_database(locale, data)
    end
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
    locals_to_sync(dedicated_locale).each do |locale|
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
          json:         true,
          open_timeout: 8,
          read_timeout: 24,
        }
      )
      raise "Can't load translations from #{url}: #{result.error}" if !result.success?

      directory = Rails.root.join('config/translations')
      if !File.directory?(directory)
        Dir.mkdir(directory, 0o755)
      end
      file = Rails.root.join(directory, "#{locale}-#{version}.yml")
      File.open(file, 'w') do |out|
        YAML.dump(result.data, out)
      end
    end
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
    rows.shift # remove header

    translation_raw = []
    rows.each do |row|
      raise "Can't import translation, source is missing" if row[0].blank?

      if row[1].blank?
        warn "Skipped #{row[0]}, because translation is blank"
        next
      end
      raise "Can't import translation, format is missing" if row[2].blank?
      raise "Can't import translation, format is invalid (#{row[2]})" if !row[2].match?(%r{^(time|string)$})

      item = {
        'locale'         => locale.locale,
        'source'         => row[0],
        'target'         => row[1],
        'target_initial' => '',
        'format'         => row[2],
      }
      translation_raw.push item
    end
    to_database(locale.name, translation_raw)
    true
  end

  def self.remote_translation_need_update?(raw, translations)
    translations.each do |row|
      next if row[1] != raw['locale']
      next if row[2] != raw['source']
      next if row[3] != raw['format']
      return false if row[4] == raw['target'] # no update if target is still the same
      return false if row[4] != row[5] # no update if translation has already changed

      return [true, Translation.find(row[0])]
    end
    [true, nil]
  end

  private_class_method def self.to_database(locale, data)
    translations = Translation.where(locale: locale).pluck(:id, :locale, :source, :format, :target, :target_initial).to_a
    ActiveRecord::Base.transaction do
      translations_to_import = []
      data.each do |translation_raw|
        result = Translation.remote_translation_need_update?(translation_raw, translations)
        next if result == false
        next if result.class != Array

        if result[1]
          result[1].update!(translation_raw.symbolize_keys!)
          result[1].save
        else
          translation_raw['updated_by_id'] = UserInfo.current_user_id || 1
          translation_raw['created_by_id'] = UserInfo.current_user_id || 1
          translations_to_import.push Translation.new(translation_raw.symbolize_keys!)
        end
      end
      if translations_to_import.present?
        Translation.import translations_to_import
      end
    end
  end

  private_class_method def self.locals_to_sync(dedicated_locale = nil)
    locales_list = []
    if dedicated_locale
      locales_list = [dedicated_locale]
    else
      locales = Locale.to_sync
      locales.each do |locale|
        locales_list.push locale.locale
      end
    end
    locales_list
  end

  private

  def set_initial
    return true if target_initial.present?
    return true if target_initial == ''

    self.target_initial = target
    true
  end

  def cache_clear
    Cache.delete("TranslationMapOnlyContent::#{locale.downcase}")
    true
  end

  def self.cache_set(locale, data)
    Cache.write("TranslationMapOnlyContent::#{locale.downcase}", data)
  end
  private_class_method :cache_set

  def self.cache_get(locale)
    Cache.read("TranslationMapOnlyContent::#{locale.downcase}")
  end
  private_class_method :cache_get
end
