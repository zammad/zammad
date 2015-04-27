# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Translation < ApplicationModel
  before_create :set_initial
  after_create  :cache_clear
  after_update  :cache_clear
  after_destroy :cache_clear

=begin

load translations from online

  Translation.load

=end

  def self.load
    url = 'http://localhost:3001/api/v1/translations'
    if !UserInfo.current_user_id
      UserInfo.current_user_id = 1
    end
    result = UserAgent.get(
      url,
      {},
      {
        :json => true,
      }
    )
    result.data.each {|translation|
      #puts translation.inspect
      exists = Translation.where(:locale => translation['locale'], :source => translation['source']).first
      if exists

        # verify if update is needed
        exists.update_attributes(translation.symbolize_keys!)
        exists.save
      else
        Translation.create(translation.symbolize_keys!)
      end
    }
    true
  end

=begin

push translations to online

  Translation.push(locale)

=end

  def self.push(locale)

    translations         = Translation.where(:locale => locale)
    translations_to_push = []
    translations.each {|translation|
      if translation.target != translation.target_initial
        translations_to_push.push translation
      end
    }

    return true if translations_to_push.empty?
    #return translations_to_push
    url = 'http://localhost:3001/api/v1/thanks_for_your_support'

    result = UserAgent.post(
      url,
      {
        :locale         => locale,
        :translations   => translations_to_push,
        :fqdn           => Setting.get('fqdn'),
        :translator_key => '',
      },
      {
        :json => true,
      }
    )
    raise result.error if !result.success?
    true
  end

=begin

get list of translations

  list = Translation.list('de')

=end

  def self.list(locale, admin = false)

    # check cache
    if !admin
      list = cache_get( locale )
    end
    if !list
      list = []
      translations = Translation.where( :locale => locale.downcase ).order( :source )
      translations.each { |item|
        if admin
          data = [
            item.id,
            item.source,
            item.target,
            item.target_initial,
          ]
          list.push data
        else
          data = [
            item.id,
            item.source,
            item.target,
          ]
          list.push data
        end
      }

      # set cache
      if !admin
        cache_set( locale, list )
      end
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

=begin

translate strings in ruby context, e. g. for notifications

  translated = Translation.translate('de', 'New')

=end

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
    if !target_initial
      self.target_initial = self.target
    end
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
