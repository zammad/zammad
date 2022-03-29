# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Translation < ApplicationModel
  include Translation::SynchronizesFromPo

  before_create :set_initial

  validates :locale, presence: true

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
      data = lang_cache_get(locale)
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
                           ]
                         else
                           [
                             item.id,
                             item.source,
                             item.target,
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
        # list.unshift presort
      end
    end
    data['list'] = presorted_list.concat list

    # set cache
    if !admin
      lang_cache_set(locale, data)
    end

    data
  end

=begin

translate strings in Ruby context, e. g. for notifications

  translated = Translation.translate('de-de', 'New')

=end

  def self.translate(locale, string)
    find_source(locale, string)&.target || string
  end

=begin

find a translation record for a given locale and source string. 'find_by' might not be enough,
because it could produce wrong matches on case insensitive MySQL databases.

=end

  def self.find_source(locale, string)
    # MySQL might find the wrong record with find_by with case insensitive locales, so use a direct comparison.
    where(locale: locale, source: string).find { |t| t.source.eql? string }
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

    record = Translation.where(locale: locale, source: 'FORMAT_DATETIME').pick(:target)
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
    record.sub!('l', timestamp.strftime('%l'))
    record.sub!('P', timestamp.strftime('%P'))
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

    record = Translation.where(locale: locale, source: 'FORMAT_DATE').pick(:target)
    return date.to_s if !record

    record.sub!('dd', format('%<day>02d', day: date.day))
    record.sub!('d', date.day.to_s)
    record.sub!('mm', format('%<month>02d', month: date.month))
    record.sub!('m', date.month.to_s)
    record.sub!('yyyy', date.year.to_s)
    record.sub!('yy', date.year.to_s.last(2))
    record
  end

  def self.remote_translation_need_update?(raw, translations)
    translations.each do |row|
      next if row[1] != raw['locale']
      next if row[2] != raw['source']
      return false if row[3] == raw['target'] # no update if target is still the same
      return false if row[3] != row[4] # no update if translation has already changed

      return [true, Translation.find(row[0])]
    end
    [true, nil]
  end

  def self.import(locale, translations)
    bulk_import translations
    lang_cache_clear(locale)
  end

  def self.lang_cache_clear(locale)
    Cache.delete lang_cache_key(locale)
  end

  def self.lang_cache_set(locale, data)
    Cache.write lang_cache_key(locale), data
  end

  def self.lang_cache_get(locale)
    Cache.read lang_cache_key(locale)
  end

  private

  def set_initial
    return true if target_initial.present?
    return true if target_initial == ''

    self.target_initial = target
    true
  end

  def cache_delete
    super
    self.class.lang_cache_clear(locale) # delete whole lang cache as well
  end

  def self.lang_cache_key(locale)
    "TranslationMapOnlyContent::#{locale.downcase}"
  end
  private_class_method :lang_cache_key
end
