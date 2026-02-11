# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Integration::SnipeitController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def verify
    response = ::Snipeit.verify(params[:api_token], params[:endpoint], verify_ssl: params[:verify_ssl])
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
    filter = params[:filter] || {}
    
    # Handle searching by asset IDs
    if params[:ids].present?
      assets = []
      Array(params[:ids]).each do |asset_id|
        begin
          response = ::Snipeit.query("hardware/#{asset_id}", {})
          assets << response if response
        rescue => e
          logger.error "Failed to fetch asset #{asset_id}: #{e.message}"
        end
      end
      render json: {
        result: { rows: assets.compact }
      }
      return
    end

    # Handle search parameter - check if it looks like an email
    if params[:search].present? && params[:search].include?('@')
      begin
        # First, search for user by email
        users_response = ::Snipeit.query('users', { search: params[:search] })
        
        if users_response && users_response['rows'].present?
          # Find exact email match
          user = users_response['rows'].find { |u| u['email']&.downcase == params[:search].downcase }
          
          if user
            logger.info "Found Snipe-IT user: #{user['username']} (ID: #{user['id']}) for email #{params[:search]}"
            
            # Now search for hardware assigned to this user
            hardware_response = ::Snipeit.query('hardware', { search: user['username'] })
            
            render json: {
              result: hardware_response || { total: 0, rows: [] }
            }
            return
          else
            logger.info "No exact email match found in Snipe-IT for #{params[:search]}"
          end
        end
      rescue => e
        logger.error "Failed to search user by email: #{e.message}"
      end
      
      # If no user found, fall through to regular search
    end

    # Regular search (not an email or no user found by email)
    if params[:search].present?
      filter[:search] = params[:search]
    end

    response = ::Snipeit.query(params[:method], filter)
    render json: {
      result: response,
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
      authorize!(ticket, :show?)
      ticket.preferences[:snipeit] ||= {}
      ticket.preferences[:snipeit][:asset_ids] = Array(params[:asset_ids]).uniq
      ticket.save!
    end

    render json: {
      result: 'ok',
    }
  end

end
