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
    error = humanize_error(e.message)
    response.headers['X-Failure'] = error.fetch(:error_human, error[:error])
    respond_to_exception(e, :unauthorized)
    http_log
  end

  private

  def respond_to_exception(e, status)
    status_code = Rack::Utils.status_code(status)

    respond_to do |format|
      format.json { render json: humanize_error(e.message), status: status }
      format.any do
        errors = humanize_error(e.message)
        @exception = e
        @message = errors[:error_human] || errors[:error] || param[:message]
        @traceback = !Rails.env.production?
        file = File.open(Rails.root.join('public', "#{status_code}.html"), 'r')
        render inline: file.read, status: status
      end
    end
  end

  def humanize_error(error)
    data = {
      error: error
    }

    case error
    when /Validation failed: (.+?)(,|$)/i
      data[:error_human] = $1
    when /(already exists|duplicate key|duplicate entry)/i
      data[:error_human] = 'Object already exists!'
    when /null value in column "(.+?)" violates not-null constraint/i
      data[:error_human] = "Attribute '#{$1}' required!"
    when /Field '(.+?)' doesn't have a default value/i
      data[:error_human] = "Attribute '#{$1}' required!"
    when 'Exceptions::NotAuthorized'
      data[:error]       = 'Not authorized'
      data[:error_human] = data[:error]
    end

    if Rails.env.production? && data[:error_human].present?
      data[:error] = data.delete(:error_human)
    end
    data
  end
end
