# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :ci do

    desc 'Re-fresh-es dynamic ENV variables'
    task refresh_envs: :environment do

      # require only at runtime of process to avoid errors when loading
      # rake tasks in production without this gem installed
      require 'dotenv'

      Dotenv.overload('fresh.env')

      result = ExternalCredential::Microsoft365.refresh_token(
        created_at:    30.days.ago,
        client_id:     ENV['MICROSOFT365_CLIENT_ID'],
        client_secret: ENV['MICROSOFT365_CLIENT_SECRET'],
        refresh_token: ENV['MICROSOFT365_REFRESH_TOKEN'],
      )

      token_env = %(MICROSOFT365_REFRESH_TOKEN='#{result[:refresh_token]}')

      Rails.root.join('fresh.env').write(token_env)
    end
  end
end
