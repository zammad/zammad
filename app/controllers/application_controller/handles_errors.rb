# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationController::HandlesErrors
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :internal_server_error
    rescue_from ExecJS::RuntimeError, with: :internal_server_error
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::StatementInvalid, with: :unprocessable_entity
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
    rescue_from ActiveRecord::DeleteRestrictionError, with: :unprocessable_entity
    rescue_from ArgumentError, with: :unprocessable_entity
    rescue_from Exceptions::UnprocessableEntity, with: :unprocessable_entity
    rescue_from Exceptions::NotAuthorized, with: :unauthorized
    rescue_from Exceptions::Forbidden, with: :forbidden
    rescue_from Pundit::NotAuthorizedError, with: :pundit_not_authorized_error
  end

  def not_found(e)
    logger.error e
    respond_to_exception(e, :not_found)
    http_log
  end

  def unprocessable_entity(e)
    logger.error e
    respond_to_exception(e, :unprocessable_entity)
    http_log
  end

  def internal_server_error(e)
    logger.error e
    respond_to_exception(e, :internal_server_error)
    http_log
  end

  def unauthorized(e)
    logger.info { e }
    error = humanize_error(e)
    response.headers['X-Failure'] = error.fetch(:error_human, error[:error])
    respond_to_exception(e, :unauthorized)
    http_log
  end

  def forbidden(e)
    logger.info { e }
    error = humanize_error(e)
    response.headers['X-Failure'] = error.fetch(:error_human, error[:error])
    respond_to_exception(e, :forbidden)
    http_log
  end

  def pundit_not_authorized_error(e)
    logger.info { e }
    # check if a special authorization_error should be shown in the result payload
    # which was raised in one of the policies. Fall back to a simple "Not authorized"
    # error to hide actual cause for security reasons.
    exeption = e.policy&.custom_exception || Exceptions::Forbidden.new('Not authorized')
    forbidden(exeption)
  end

  private

  def respond_to_exception(e, status)
    status_code = Rack::Utils.status_code(status)

    respond_to do |format|
      format.json { render json: humanize_error(e), status: status }
      format.any do
        errors = humanize_error(e)
        @exception = e
        @message = errors[:error_human] || errors[:error] || param[:message]
        @traceback = !Rails.env.production?
        file = File.open(Rails.root.join('public', "#{status_code}.html"), 'r')
        render inline: file.read, status: status, content_type: 'text/html' # rubocop:disable Rails/RenderInline
      end
    end
  end

  def humanize_error(e)

    data = {
      error: e.message
    }

    if e.message =~ %r{Validation failed: (.+?)(,|$)}i
      data[:error_human] = $1
    elsif e.message.match?(%r{(already exists|duplicate key|duplicate entry)}i)
      data[:error_human] = 'Object already exists!'
    elsif e.message =~ %r{null value in column "(.+?)" violates not-null constraint}i || e.message =~ %r{Field '(.+?)' doesn't have a default value}i
      data[:error_human] = "Attribute '#{$1}' required!"
    elsif e.message == 'Exceptions::Forbidden'
      data[:error]       = 'Not authorized'
      data[:error_human] = data[:error]
    elsif e.message == 'Exceptions::NotAuthorized'
      data[:error]       = 'Authorization failed'
      data[:error_human] = data[:error]
    elsif [ActionController::RoutingError, ActiveRecord::RecordNotFound, Exceptions::UnprocessableEntity, Exceptions::NotAuthorized, Exceptions::Forbidden].include?(e.class)
      data[:error_human] = data[:error]
    end

    if data[:error_human].present?
      data[:error] = data[:error_human]
    elsif !current_user&.permissions?('admin')
      # We want to avoid leaking of internal information but also want the user
      # to give the administrator a reference to find the cause of the error.
      # Therefore we generate a one time unique error ID that can be used to
      # search the logs and find the actual error message.
      error_code_prefix = "Error ID #{SecureRandom.urlsafe_base64(6)}:"
      Rails.logger.error "#{error_code_prefix} #{data[:error]}"
      data[:error] = "#{error_code_prefix} Please contact your administrator."
    end

    data
  end
end
