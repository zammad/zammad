# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue2100Utf8EncodeHttpLogs < ActiveRecord::Migration[5.1]
  def up
    HttpLog.where('request LIKE :enctag OR response LIKE :enctag', enctag: '%content: !binary |%')
           .limit(100_000)
           .reorder(created_at: :desc)
           .find_each do |log|
             log.update(request: utf8_encode(log.request), response: utf8_encode(log.response))
           end
  end

  private

  def utf8_encode(messages)
    messages.transform_values { |value| value.is_a?(String) ? TextEncoding.utf8_encode(value) : value }
  end
end
