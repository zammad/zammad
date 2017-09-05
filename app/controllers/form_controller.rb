# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class FormController < ApplicationController
  skip_before_action :verify_csrf_token
  before_action :cors_preflight_check_execute
  after_action :set_access_control_headers_execute

  def configuration
    return if !enabled?
    return if !fingerprint_exists?
    return if limit_reached?

    api_path  = Rails.configuration.api_path
    http_type = Setting.get('http_type')
    fqdn      = Setting.get('fqdn')

    endpoint = "#{http_type}://#{fqdn}#{api_path}/form_submit"

    result = {
      enabled:  Setting.get('form_ticket_create'),
      endpoint: endpoint,
      token:    token_gen(params[:fingerprint])
    }

    if params[:test] && current_user && current_user.permissions?('admin.channel_formular')
      result[:enabled] = true
    end

    render json: result, status: :ok
  end

  def submit
    return if !enabled?
    return if !fingerprint_exists?
    return if !token_valid?(params[:token], params[:fingerprint])
    return if limit_reached?

    # validate input
    errors = {}
    if params[:name].blank?
      errors['name'] = 'required'
    end
    if params[:email].blank?
      errors['email'] = 'required'
    elsif params[:email] !~ /@/
      errors['email'] = 'invalid'
    elsif params[:email] =~ /(>|<|\||\!|"|§|'|\$|%|&|\(|\)|\?|\s|\.\.)/
      errors['email'] = 'invalid'
    end
    if params[:title].blank?
      errors['title'] = 'required'
    end
    if params[:body].blank?
      errors['body'] = 'required'
    end

    # realtime verify
    if errors['email'].blank?
      begin
        address = ValidEmail2::Address.new(params[:email])
        if !address || !address.valid? || !address.valid_mx?
          errors['email'] = 'invalid'
        end
      rescue => e
        message = e.to_s
        Rails.logger.info "Can't verify email #{params[:email]}: #{message}"

        # ignore 450, graylistings
        if message !~ /450/
          errors['email'] = message
        end
      end
    end

    if errors.present?
      render json: {
        errors: errors
      }, status: :ok
      return
    end

    name = params[:name].strip
    email = params[:email].strip.downcase

    customer = User.find_by(email: email)
    if !customer
      role_ids = Role.signup_role_ids
      customer = User.create(
        firstname: name,
        lastname: '',
        email: email,
        active: true,
        role_ids: role_ids,
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

    # set current user
    UserInfo.current_user_id = customer.id

    group = Group.find_by(id: Setting.get('form_ticket_create_group_id'))
    if !group
      group = Group.where(active: true).first
      if !group
        group = Group.first
      end
    end
    ticket = Ticket.create!(
      group_id: group.id,
      customer_id: customer.id,
      title: params[:title],
      preferences: {
        form: {
          remote_ip: request.remote_ip,
          fingerprint_md5: Digest::MD5.hexdigest(params[:fingerprint]),
        }
      }
    )
    article = Ticket::Article.create!(
      ticket_id: ticket.id,
      type_id: Ticket::Article::Type.find_by(name: 'web').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
      body: params[:body],
      subject: params[:title],
      internal: false,
    )

    if params[:file]

      params[:file].each { |file|
        Store.add(
          object: 'Ticket::Article',
          o_id: article.id,
          data: file.read,
          filename: file.original_filename,
          preferences: {
            'Mime-Type' => file.content_type,
          }
        )
      }
    end

    UserInfo.current_user_id = 1

    result = {
      ticket: {
        id: ticket.id,
        number: ticket.number
      }
    }
    render json: result, status: :ok
  end

  private

  def token_gen(fingerprint)
    crypt = ActiveSupport::MessageEncryptor.new(Setting.get('application_secret')[0, 32])
    fingerprint = "#{Base64.strict_encode64(Setting.get('fqdn'))}:#{Time.zone.now.to_i}:#{Base64.strict_encode64(fingerprint)}"
    Base64.strict_encode64(crypt.encrypt_and_sign(fingerprint))
  end

  def token_valid?(token, fingerprint)
    if token.blank?
      Rails.logger.info 'No token for form!'
      response_access_deny
      return false
    end
    begin
      crypt = ActiveSupport::MessageEncryptor.new(Setting.get('application_secret')[0, 32])
      result = crypt.decrypt_and_verify(Base64.decode64(token))
    rescue
      Rails.logger.info 'Invalid token for form!'
      response_access_deny
      return false
    end
    if result.blank?
      Rails.logger.info 'Invalid token for form!'
      response_access_deny
      return false
    end
    parts = result.split(/:/)
    if parts.count != 3
      Rails.logger.info "Invalid token for form (need to have 3 parts, only #{parts.count} found)!"
      response_access_deny
      return false
    end
    fqdn_local = Base64.decode64(parts[0])
    if fqdn_local != Setting.get('fqdn')
      Rails.logger.info "Invalid token for form (invalid fqdn found #{fqdn_local} != #{Setting.get('fqdn')})!"
      response_access_deny
      return false
    end
    fingerprint_local = Base64.decode64(parts[2])
    if fingerprint_local != fingerprint
      Rails.logger.info "Invalid token for form (invalid fingerprint found #{fingerprint_local} != #{fingerprint})!"
      response_access_deny
      return false
    end
    if parts[1].to_i < (Time.zone.now.to_i - 60 * 60 * 24)
      Rails.logger.info 'Invalid token for form (token expired})!'
      response_access_deny
      return false
    end
    true
  end

  def limit_reached?
    return false if !SearchIndexBackend.enabled?

    form_limit_by_ip_per_hour = Setting.get('form_ticket_create_by_ip_per_hour') || 20
    result = SearchIndexBackend.search("preferences.form.remote_ip:'#{request.remote_ip}' AND created_at:>now-1h", form_limit_by_ip_per_hour, 'Ticket')
    if result.count >= form_limit_by_ip_per_hour.to_i
      response_access_deny
      return true
    end

    form_limit_by_ip_per_day = Setting.get('form_ticket_create_by_ip_per_day') || 240
    result = SearchIndexBackend.search("preferences.form.remote_ip:'#{request.remote_ip}' AND created_at:>now-1d", form_limit_by_ip_per_day, 'Ticket')
    if result.count >= form_limit_by_ip_per_day.to_i
      response_access_deny
      return true
    end

    form_limit_per_day = Setting.get('form_ticket_create_per_day') || 5000
    result = SearchIndexBackend.search('preferences.form.remote_ip:* AND created_at:>now-1d', form_limit_per_day, 'Ticket')
    if result.count >= form_limit_per_day.to_i
      response_access_deny
      return true
    end

    false
  end

  def fingerprint_exists?
    return true if params[:fingerprint].present? && params[:fingerprint].length > 30
    Rails.logger.info 'No fingerprint given!'
    response_access_deny
    false
  end

  def enabled?
    return true if params[:test] && current_user && current_user.permissions?('admin.channel_formular')
    return true if Setting.get('form_ticket_create')
    response_access_deny
    false
  end

end
