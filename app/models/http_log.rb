# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class HttpLog < ApplicationModel
  store :request
  store :response

=begin

cleanup old http logs

  HttpLog.cleanup

optional you can put the max oldest chat entries as argument

  HttpLog.cleanup(1.month)

=end

  def self.cleanup(diff = 1.month)
    HttpLog.where('created_at < ?', Time.zone.now - diff).delete_all
    true
  end

end
