# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class HttpLogTokenHeaderCleanup < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    http_log_cleanup
  end

  private

  def http_log_cleanup
    HttpLog
      .where('LOWER(request) LIKE :token OR LOWER(response) LIKE :token', token: '%-token:%')
      .find_each(batch_size: 250) do |log|
        log.send(:filter_sensitive_data)
        log.save!(validate: false)
      end
  end
end
