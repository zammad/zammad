# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do # rubocop:disable Metrics/BlockLength

  namespace :ci do # rubocop:disable Metrics/BlockLength

    def update_ci_variable(credentials_class, name)
      puts "Trying to fetch a new #{name}..."

      result = credentials_class.refresh_token(
        created_at:    30.days.ago,
        client_id:     ENV['MICROSOFT365_CLIENT_ID'],
        client_secret: ENV['MICROSOFT365_CLIENT_SECRET'],
        client_tenant: ENV['MICROSOFT365_CLIENT_TENANT'],
        refresh_token: ENV[name],
      )

      if !result[:refresh_token].presence
        pp result
        raise "Error: a new #{name} could not be found."
      end

      puts "Trying to update the corresponding CI variable with the new token #{result[:refresh_token]}..."

      api_result = UserAgent.put(
        "#{ENV['CI_API_V4_URL']}/projects/#{ENV['CI_PROJECT_ID']}/variables/#{name}",
        {
          value: result[:refresh_token],
        },
        {
          headers: {
            'PRIVATE-TOKEN' => ENV['CI_VARIABLE_UPDATE_TOKEN']
          }
        },
      )

      return if api_result.success?

      pp api_result
      raise 'Error: the CI variable could not be updated. Please make sure that CI_VARIABLE_UPDATE_TOKEN has a valid token.'

    end

    desc 'Update CI variables that need it, like refresh tokens'
    task update_ci_variables: :environment do

      %w[MICROSOFT365_CLIENT_ID MICROSOFT365_CLIENT_SECRET MICROSOFT365_CLIENT_TENANT MICROSOFT365_REFRESH_TOKEN MICROSOFTGRAPH_REFRESH_TOKEN CI_VARIABLE_UPDATE_TOKEN].each do |var|
        raise "Error: the required environment variable #{var} was not found." if !ENV[var].presence
      end

      update_ci_variable(ExternalCredential::Microsoft365, 'MICROSOFT365_REFRESH_TOKEN')
      update_ci_variable(ExternalCredential::MicrosoftGraph, 'MICROSOFTGRAPH_REFRESH_TOKEN')

      puts 'Done.'
    end
  end
end
