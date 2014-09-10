# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Translation < ApplicationModel
  before_create :set_initial
  after_create  :cache_clear
  after_update  :cache_clear
  after_destroy :cache_clear

  def self.list(locale)

    # check cache
    list = cache_get( locale )
    if !list
      list = []
      translations = Translation.where( :locale => locale.downcase )
      translations.each { |item|
        data = [
          item.id,
          item.source,
          item.target,
        ]
        list.push data
      }

      # set cache
      cache_set( locale, list )
    end

    timestamp_map_default = 'yyyy-mm-dd HH:MM'
    timestamp_map = {
      :de => 'dd.mm.yyyy HH:MM',
    }
    timestamp = timestamp_map[ locale.to_sym ] || timestamp_map_default

    date_map_default = 'yyyy-mm-dd'
    date_map = {
      :de => 'dd.mm.yyyy',
    }
    date = date_map[ locale.to_sym ] || date_map_default

    return {
      :list            => list,
      :timestampFormat => timestamp,
      :dateFormat      => date,
    }
  end

  def self.translate(locale, string)

    # translate string
    records = Translation.where( :locale => locale, :source => string )
    records.each {|record|
      return record.target if record.source == string
    }

    # fallback lookup in en
    records = Translation.where( :locale => 'en', :source => string )
    records.each {|record|
      return record.target if record.source == string
    }

    return string
  end

  private
  def set_initial
    self.target_initial = self.target
  end
  def cache_clear
    Cache.delete( 'Translation::' + self.locale.downcase )
  end
  def self.cache_set(locale, data)
    Cache.write( 'Translation::' + locale.downcase, data )
  end
  def self.cache_get(locale)
    Cache.get( 'Translation::' + locale.downcase )
  end
end
