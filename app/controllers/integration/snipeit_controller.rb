# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Integration::SnipeitController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  # Not applied to #verify, because admins have to be able to test a configuration before
  # switching the integration on.
  before_action :check_integration_enabled, only: %i[query update]

  SENSITIVE_FIELDS = [:api_token].freeze

  # Endpoints the legacy frontend is allowed to reach through the generic query action.
  ALLOWED_QUERY_METHODS = %w[hardware users categories models].freeze

  def verify
    unmasked_params = unmask_sensitive_params(params, Setting.get('snipeit_config'))

    response = ::Snipeit.verify(unmasked_params[:api_token], unmasked_params[:endpoint], verify_ssl: unmasked_params[:verify_ssl])
    render json: {
      result:   'ok',
      response: response,
    }
  rescue => e
    logger.error e

    render json: {
      result:  'failed',
      message: e.message,
    }
  end

  def query
    result   = assets_by_ids if params[:ids].present?
    result ||= assets_by_customer_email(params[:search]) if customer_email_search?
    result ||= ::Snipeit.query(query_method, query_filter)

    render json: {
      result: result,
    }
  rescue => e
    logger.error e

    render json: {
      result:  'failed',
      message: e.message,
    }
  end

  def update
    params[:asset_ids] ||= []
    ticket = Ticket.find(params[:ticket_id])
    ticket.with_lock do
      authorize!(ticket, :update?)
      ticket.preferences[:snipeit] ||= {}
      ticket.preferences[:snipeit][:asset_ids] = Array(params[:asset_ids]).map(&:to_i).uniq
      ticket.save!
    end

    render json: {
      result: 'ok',
    }
  end

  private

  def check_integration_enabled
    Service::CheckFeatureEnabled.execute(
      name:                   'snipeit_integration',
      custom_exception_class: Exceptions::Forbidden,
      custom_error_message:   __('Snipe-IT integration is not enabled'),
    )
  end

  def query_method
    method = params[:method].presence || 'hardware'
    raise format(__("Unsupported Snipe-IT query method '%s'."), method) if ALLOWED_QUERY_METHODS.exclude?(method)

    method
  end

  def query_filter
    filter = params[:filter].present? ? params[:filter].permit!.to_h.symbolize_keys : {}
    filter[:search] = params[:search] if params[:search].present?
    filter
  end

  def assets_by_ids
    rows = Array(params[:ids]).filter_map do |asset_id|
      ::Snipeit.asset(asset_id)
    rescue => e
      logger.error "Failed to fetch asset #{asset_id}: #{e.message}"
      nil
    end

    { rows: rows }
  end

  def customer_email_search?
    params[:search].present? && params[:search].include?('@')
  end

  # Look up the Snipe-IT user for the given customer email and return the assets assigned
  # to them. Returns nil if no matching user exists, so that the caller falls back to a
  # regular search.
  def assets_by_customer_email(email)
    user = snipeit_user_by_email(email)
    if !user
      logger.info "No exact email match found in Snipe-IT for #{email}"
      return
    end

    logger.info "Found Snipe-IT user: #{user['username']} (ID: #{user['id']}) for email #{email}"

    ::Snipeit.query('hardware', {
                      assigned_to:   user['id'],
                      assigned_type: 'App\\Models\\User',
                    }) || { total: 0, rows: [] }
  rescue => e
    logger.error "Failed to search user by email: #{e.message}"
    nil
  end

  # Snipe-IT matches 'email' exactly, unlike 'search', which would return a fuzzy first page
  # the customer may not even be part of. The find below stays as a defensive re-check.
  def snipeit_user_by_email(email)
    response = ::Snipeit.query('users', { email: email })
    return if response.blank? || response['rows'].blank?

    response['rows'].find { |user| user['email']&.downcase == email.downcase }
  end
end
