# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue2100Utf8EncodeHttpLogs < ActiveRecord::Migration[5.1]
  def up
    HttpLog.where('request LIKE :enctag OR response LIKE :enctag', enctag: '%content: !binary |%')
           .limit(100_000)
           .order(created_at: :desc)
           .find_each do |log|
             log.update(request:  log.request.transform_values(&:utf8_encode),
                        response: log.response.transform_values(&:utf8_encode))
           end
  end
end
