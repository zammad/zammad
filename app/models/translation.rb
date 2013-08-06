# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Translation < ApplicationModel
  before_create :set_initial

  def self.list(locale)
    translations = Translation.where( :locale => locale )
    list = []
    translations.each { |item|
      data = [
        item.id,
        item.source,
        item.target,
      ]
      list.push data
    }

    timestamp_map_default = 'yyyy-mm-dd HH:MM'
    timestamp_map = {
      :de => 'dd.mm.yyyy HH:MM',
    }
    timestamp = timestamp_map[ locale.to_sym ] || timestamp_map_default
    return {
      :list            => list,
      :timestampFormat => timestamp,
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
end
