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

=begin

fetch a single hardware asset by id

  asset = Snipeit.asset(42)

Snipe-IT offers no bulk lookup by id, so linked assets have to be fetched one by one.
The short-lived cache keeps the repeated lookups of the same ids (sidebar badge, sidebar
list, re-render after every add / remove) from turning into individual HTTP requests.

returns the raw API hash, or nil if the asset does not exist. Callers which need the flat
structure used by the GraphQL types have to apply .normalize_asset themselves, because the
legacy sidebar renders the nested Snipe-IT keys directly.

Misses are not cached, so an asset which was just created in Snipe-IT is linkable right
away instead of reporting 'not found' until the entry expires.

=end

  def self.asset(asset_id)
    Rails.cache.fetch("Snipeit/hardware/#{asset_id.to_i}", expires_in: 1.minute, skip_nil: true) do
      response = query("hardware/#{asset_id.to_i}")
      response.is_a?(Hash) && response['id'] ? response : nil
    end
  end

=begin

readable label for a hardware asset, for use in the ticket history

  label = Snipeit.asset_label(42)

Assets live in Snipe-IT, so a history entry has to carry a label of its own - the bare id
would be meaningless once the link is gone. Falls back to the id if the asset can no longer
be fetched, because a broken Snipe-IT connection must not stop a ticket from being saved.

=end

  def self.asset_label(asset_id)
    api_asset = asset(asset_id)
    return asset_id.to_s if api_asset.blank?

    api_asset['asset_tag'].presence || api_asset['name'].presence || asset_id.to_s
  rescue => e
    Rails.logger.error "Failed to fetch Snipe-IT asset #{asset_id} for the ticket history: #{e.message}"
    asset_id.to_s
  end

=begin

look up a Snipe-IT user by email address

  user = Snipeit.user_by_email('nicole.braun@zammad.org')

Snipe-IT matches 'email' exactly, unlike 'search', which would return a fuzzy page the
wanted user may not even be part of. The find below stays as a defensive re-check.

returns the raw user hash, or nil if no user has that address.

=end

  def self.user_by_email(email)
    return if email.blank?

    response = query('users', { email: email })
    return if response.blank? || response['rows'].blank?

    response['rows'].find { |user| user['email']&.downcase == email.downcase }
  end

=begin

hardware assets currently assigned to the Snipe-IT user with the given email address

  assets = Snipeit.assets_assigned_to_email('nicole.braun@zammad.org')

returns an array of raw assets, or nil if no Snipe-IT user has that address - so callers
can tell 'unknown customer' apart from 'customer without assets'.

=end

  def self.assets_assigned_to_email(email, limit: nil)
    user = user_by_email(email)
    return if user.blank?

    params = { assigned_to: user['id'], assigned_type: 'App\\Models\\User' }
    params[:limit] = limit if limit

    response = query('hardware', params)
    response.is_a?(Hash) && response['rows'].is_a?(Array) ? response['rows'] : []
  end

=begin

normalize a raw Snipe-IT hardware asset into the flat structure used by the GraphQL types

  asset = Snipeit.normalize_asset(api_asset)

=end

  def self.normalize_asset(asset)
    {
      'id'            => asset['id'],
      'name'          => asset['name'] || asset['asset_tag'],
      'asset_tag'     => asset['asset_tag'],
      'serial'        => asset['serial'],
      'link'          => asset['link'],
      'model_name'    => asset.dig('model', 'name'),
      'status_name'   => asset.dig('status_label', 'name'),
      'category_name' => asset.dig('category', 'name'),
      'location_name' => asset.dig('location', 'name'),
    }
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

    raise format(__("Can't fetch data from %s: %s"), url, result.error) if !result.success?

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
    raise format(__("Invalid endpoint '%s', need to start with http:// or https://"), url) if !url.match?(%r{^https?://}i)

    url = _url_cleanup_baseurl(url)
    url = "#{url}/api/v1"
    url.gsub(%r{([^:])//+}, '\\1/')
  end

  def self._url_cleanup_baseurl(url)
    url = url.strip.gsub(%r{/+$}, '')
    raise format(__("Invalid endpoint '%s', need to start with http:// or https://"), url) if !url.match?(%r{^https?://}i)

    url.gsub!(%r{/api/v1.*$}, '')
    url.gsub(%r{([^:])//+}, '\\1/')
  end
end
