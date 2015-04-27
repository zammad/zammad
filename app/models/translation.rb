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
    url = 'https://i18n.zammad.com/api/v1/translations'
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
    raise "Can't load translations from #{url}: #{result.error}" if !result.success?
    result.data.each {|translation|
      #puts translation.inspect

      # handle case insensitive sql
      exists     = Translation.where(:locale => translation['locale'], :format => translation['format'], :source => translation['source'])
      translaten = nil
      exists.each {|item|
        if item.source == translation['source']
          translaten = item
        end
      }
      if translaten

        # verify if update is needed
        translaten.update_attributes(translation.symbolize_keys!)
        translaten.save
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

    # only push changed translations
    translations         = Translation.where(:locale => locale)
    translations_to_push = []
    translations.each {|translation|
      if translation.target != translation.target_initial
        translations_to_push.push translation
      end
    }

    return true if translations_to_push.empty?
    #return translations_to_push
    url = 'https://i18n.zammad.com/api/v1/thanks_for_your_support'

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
    raise "Can't push translations to #{url}: #{result.error}" if !result.success?
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
            item.format,
          ]
          list.push data
        else
          data = [
            item.id,
            item.source,
            item.target,
            item.format,
          ]
          list.push data
        end
      }

      # set cache
      if !admin
        cache_set( locale, list )
      end
    end

    return {
      :list => list,
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
