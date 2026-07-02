# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class HttpLogBearerTokenCleanup < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    http_log_cleanup
  end

  private

  def http_log_cleanup
    HttpLog
      .where('LOWER(request) LIKE :bearer OR LOWER(response) LIKE :bearer', bearer: '%authorization:%bearer%')
      .find_each(batch_size: 250) do |log|
        log.send(:filter_sensitive_data)
        log.save!(validate: false)
      end
  end
end
