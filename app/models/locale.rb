# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Locale < ApplicationModel

=begin

get locals to sync

all:

  Locale.sync

returns

 ['en-us', 'de-de', ...]

=end

  def self.to_sync
    locales = Locale.where(active: true)
    if Rails.env.test?
      locales = Locale.where(active: true, locale: ['en-us'])
    end

    # read used locales based on env, e. g. export Z_LOCALES='en-us:de-de'
    if ENV['Z_LOCALES']
      locales = Locale.where(active: true, locale: ENV['Z_LOCALES'].split(':') )
    end
    locales
  end

=begin

load locales from online

all:

  Locale.load

=end

  def self.load
    url = 'https://i18n.zammad.com/api/v1/locales'

    result = UserAgent.get(
      url,
      {},
      {
        json: true,
      }
    )

    raise "Can't load locales from #{url}" if !result
    raise "Can't load locales from #{url}: #{result.error}" if !result.success?

    ActiveRecord::Base.transaction do
      result.data.each { |locale|
        exists = Locale.find_by(locale: locale['locale'])
        if exists
          exists.update(locale.symbolize_keys!)
        else
          Locale.create(locale.symbolize_keys!)
        end
      }
    end
    true
  end

end
