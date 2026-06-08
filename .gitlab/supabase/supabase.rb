#!/usr/bin/env ruby
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Supabase
  REQUIRED_ENV_VARS = %w[SUPABASE_HOSTNAME SUPABASE_ANON_API_KEY SUPABASE_USERNAME SUPABASE_PASSWORD].freeze

  def self.token
    REQUIRED_ENV_VARS.select { ENV[it].blank? }.each do |env_var| # rubocop:disable Lint/UnreachableLoop
      raise "The required environment variable #{env_var} is not set. Exiting."
    end

    @token ||= login
  end

  def self.login
    uri = URI.parse("https://#{ENV['SUPABASE_HOSTNAME']}/auth/v1/token?grant_type=password")
    headers = {
      'Content-Type' => 'application/json',
      'apikey'       => ENV['SUPABASE_ANON_API_KEY'],
    }
    payload = {
      'email'    => ENV['SUPABASE_USERNAME'],
      'password' => ENV['SUPABASE_PASSWORD'],
    }

    res = Net::HTTP.post(uri, payload.to_json, headers)

    return JSON.parse(res.body)['access_token'] if res.is_a?(Net::HTTPSuccess)

    raise "Supabase login failed: #{res.code} #{res.message} #{res.body}"
  end

  def self.submit(table_name, payload)
    uri = URI.parse("https://#{ENV['SUPABASE_HOSTNAME']}/rest/v1/#{table_name}")
    headers = {
      'Content-Type'  => 'application/json',
      'Authorization' => "Bearer #{token}",
      'apikey'        => ENV['SUPABASE_ANON_API_KEY'],
    }
    res = Net::HTTP.post(uri, payload.to_json, headers)

    return if res.is_a?(Net::HTTPSuccess)

    raise "Supabase request failed: #{res.code} #{res.message} #{res.body}"
  end
end
