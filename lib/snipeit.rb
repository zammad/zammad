# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'cgi'

class Snipeit

=begin

verify Snipe-IT configuration

  result = Snipeit.verify(api_token, endpoint, verify_ssl: false)

returns

  array with hardware assets or an exception if no data was able to be retrieved

=end

  def self.verify(api_token, endpoint, verify_ssl: false)
    raise __('Invalid Snipe-IT configuration (missing endpoint or api_token).') if api_token.blank? || endpoint.blank?

    _query('hardware', {}, _url_cleanup(endpoint), api_token, verify_ssl: verify_ssl)
  end

=begin

query Snipe-IT API

  result = Snipeit.query(method, params)

  result = Snipeit.query('hardware', { search: 'laptop' })

returns for hardware:

  {
    "total": 2,
    "rows": [
      {
        "id": 1,
        "name": "Laptop-001",
        "asset_tag": "LAP001",
        "serial": "ABC123",
        "model": {
          "id": 1,
          "name": "MacBook Pro"
        },
        "status_label": {
          "id": 2,
          "name": "Ready to Deploy",
          "status_type": "deployable",
          "status_meta": "deployed"
        },
        "category": {
          "id": 1,
          "name": "Laptops"
        },
        "manufacturer": {
          "id": 1,
          "name": "Apple"
        },
        "location": {
          "id": 1,
          "name": "HQ"
        },
        "assigned_to": {
          "id": 1,
          "name": "John Doe",
          "type": "user"
        },
        "notes": "Some notes",
        "created_at": {
          "datetime": "2024-01-01 10:00:00",
          "formatted": "Mon Jan 01, 2024 10:00 AM"
        },
        "updated_at": {
          "datetime": "2024-01-15 14:30:00",
          "formatted": "Mon Jan 15, 2024 02:30 PM"
        }
      }
    ]
  }

=end

  def self.query(method, params = {})
    setting = Setting.get('snipeit_config')
    raise __("The required field 'api_token' is missing from the config.") if setting[:api_token].blank?
    raise __("The required field 'endpoint' is missing from the config.") if setting[:endpoint].blank?

    _query(method, params, _url_cleanup(setting[:endpoint]), setting[:api_token], verify_ssl: setting[:verify_ssl])
  end

  def self._query(method, params, url, api_token, verify_ssl: false)
    # Build query parameters
    query_params = params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
    full_url = query_params.present? ? "#{url}/#{method}?#{query_params}" : "#{url}/#{method}"

    result = UserAgent.get(
      full_url,
      {},
      {
        verify_ssl:   verify_ssl,
        json:         true,
        open_timeout: 6,
        read_timeout: 16,
        headers:      {
          'Authorization' => "Bearer #{api_token}",
          'Accept'        => 'application/json',
        },
        log:          {
          facility: 'snipeit',
        },
      },
    )

    raise "Can't fetch data from #{url}: #{result.error}" if !result.success?

    data = result.data

    # add link to assets
    if data['rows'].is_a?(Array)
      data['rows'].each do |item|
        next if !item['id']

        item['link'] = "#{_url_cleanup_baseurl(url)}/hardware/#{item['id']}"
      end
    elsif data['id'].present?
      # Single asset response
      data['link'] = "#{_url_cleanup_baseurl(url)}/hardware/#{data['id']}"
    end

    data
  end

  def self._url_cleanup(url)
    url = url.strip.gsub(%r{/+$}, '')
    raise "Invalid endpoint '#{url}', need to start with http:// or https://" if !url.match?(%r{^https?://}i)

    url = _url_cleanup_baseurl(url)
    url = "#{url}/api/v1"
    url.gsub(%r{([^:])//+}, '\\1/')
  end

  def self._url_cleanup_baseurl(url)
    url = url.strip.gsub(%r{/+$}, '')
    raise "Invalid endpoint '#{url}', need to start with http:// or https://" if !url.match?(%r{^https?://}i)

    url.gsub!(%r{/api/v1.*$}, '')
    url.gsub(%r{([^:])//+}, '\\1/')
  end
end
