# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Locale < ApplicationModel

  def self.load
    url = 'https://i18n.zammad.com/api/v1/locales'

    result = UserAgent.get(
      url,
      {},
      {
        :json => true,
      }
    )
    result.data.each {|locale|
      puts locale.inspect
      exists = Locale.where(:locale => locale['locale']).first
      if exists
        exists.update(locale.symbolize_keys!)
      else
        Locale.create(locale.symbolize_keys!)
      end
    }
    true
  end

end