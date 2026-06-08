# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormController < ApplicationController
  prepend_before_action -> { authorize! }, only: %i[configuration submit]

  skip_before_action :verify_csrf_token
  before_action :cors_preflight_check
  after_action :set_access_control_headers_execute
  skip_before_action :user_device_log

  def configuration
    return if !fingerprint_exists?

    api_path  = Rails.configuration.api_path
    http_type = Setting.get('http_type')
    fqdn      = Setting.get('fqdn')

    endpoint = "#{http_type}://#{fqdn}#{api_path}/form_submit"

    result = {
      enabled:  Setting.get('form_ticket_create'),
      endpoint: endpoint,
      token:    token_gen(params[:fingerprint])
    }

    if authorized?(policy_record, :test?)
      result[:enabled] = true
    end

    render json: result, status: :ok
  end

  def submit
    return if !fingerprint_exists?
    return if !token_valid?(params[:token], params[:fingerprint])

    if (errors = validate_params) && errors.present?
      render json: { errors: }, status: :ok
      return
    end

    customer = fetch_customer

    ticket = UserInfo.with_user_id(customer.id) do
      if Setting.get('form_allowed_params').blank?
        ApplicationHandleInfo.in_context('form') do
          create_ticket(customer)
        end
      else
        create_ticket(customer)
      end
    end

    result = {
      ticket: {
        id:     ticket.id,
        number: ticket.number
      }
    }
    render json: result, status: :ok
  end

  private

  # we don't wann to tell what the cause for the authorization error is
  # so we capture the exception and raise an anonymized one
  def authorize!(...)
    super
  rescue Pundit::NotAuthorizedError
    raise Exceptions::Forbidden
  end

  def token_gen(fingerprint)
    crypt = ActiveSupport::MessageEncryptor.new(Setting.get('application_secret')[0, 32], serializer: JSON)
    fingerprint = "#{Base64.strict_encode64(Setting.get('fqdn'))}:#{Time.zone.now.to_i}:#{Base64.strict_encode64(fingerprint)}"
    Base64.strict_encode64(crypt.encrypt_and_sign(fingerprint))
  end

  def token_valid?(token, fingerprint)
    if token.blank?
      Rails.logger.info 'No token for form!'
      raise Exceptions::Forbidden
    end
    begin
      crypt = ActiveSupport::MessageEncryptor.new(Setting.get('application_secret')[0, 32], serializer: JSON)
      result = crypt.decrypt_and_verify(Base64.decode64(token))
    rescue
      Rails.logger.info 'Invalid token for form!'
      raise Exceptions::NotAuthorized
    end
    if result.blank?
      Rails.logger.info 'Invalid token for form!'
      raise Exceptions::NotAuthorized
    end
    parts = result.split(':')
    if parts.count != 3
      Rails.logger.info "Invalid token for form (need to have 3 parts, only #{parts.count} found)!"
      raise Exceptions::NotAuthorized
    end
    fqdn_local = Base64.decode64(parts[0])
    if fqdn_local != Setting.get('fqdn')
      Rails.logger.info "Invalid token for form (invalid fqdn found #{fqdn_local} != #{Setting.get('fqdn')})!"
      raise Exceptions::NotAuthorized
    end
    fingerprint_local = Base64.decode64(parts[2])
    if fingerprint_local != fingerprint
      Rails.logger.info "Invalid token for form (invalid fingerprint found #{fingerprint_local} != #{fingerprint})!"
      raise Exceptions::NotAuthorized
    end
    if parts[1].to_i < (Time.zone.now.to_i - (60 * 60 * 24))
      Rails.logger.info 'Invalid token for form (token expired})!'
      raise Exceptions::NotAuthorized
    end
    true
  end

  def fingerprint_exists?
    return true if params[:fingerprint].present? && params[:fingerprint].length > 30

    Rails.logger.info "The required parameter 'fingerprint' is missing or invalid."
    raise Exceptions::Forbidden
  end

  def validate_params
    errors = {}

    if params[:name].blank?
      errors['name'] = 'required'
    end
    if params[:title].blank?
      errors['title'] = 'required'
    end
    if params[:body].blank?
      errors['body'] = 'required'
    end

    if params[:email].blank?
      errors['email'] = 'required'
    else
      begin
        email_address_validation = EmailAddressValidation.new(params[:email])
        if !email_address_validation.valid?(check_mx: true)
          errors['email'] = 'invalid'
        end
      rescue => e
        message = e.to_s
        Rails.logger.info "Can't verify email #{params[:email]}: #{message}"

        # ignore 450, graylistings
        errors['email'] = message if message.exclude?('450')
      end
    end

    errors
  end

  def fetch_customer
    name  = params[:name].strip
    email = params[:email].strip.downcase

    User.create_with(
      firstname:     name,
      lastname:      '',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    ).find_or_create_by(email:)
  end

  def create_ticket(customer)
    group = Group.find_by(id: Setting.get('form_ticket_create_group_id')) || Group.where(active: true).first || Group.first

    ticket = Ticket.create!(
      group_id:    group.id,
      customer_id: customer.id,
      preferences: {
        form: {
          remote_ip:       request.remote_ip,
          fingerprint_md5: Digest::MD5.hexdigest(params[:fingerprint]),
        }
      },
      **ticket_attributes
    )

    article = Ticket::Article.create!(
      ticket_id: ticket.id,
      type_id:   Ticket::Article::Type.find_by(name: 'web').id,
      sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
      body:      params[:body],
      subject:   params[:title],
      internal:  false,
    )

    params[:file]&.each do |file|
      Store.create!(
        object:      'Ticket::Article',
        o_id:        article.id,
        data:        file.read,
        filename:    file.original_filename,
        preferences: {
          'Mime-Type' => file.content_type,
        }
      )
    end

    ticket
  end

  def ticket_attributes
    attrs = [:title] + Setting.get('form_allowed_params')

    params.permit!.slice(*attrs)
  end
end
