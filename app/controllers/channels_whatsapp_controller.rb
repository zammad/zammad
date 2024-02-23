# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ChannelsWhatsappController < ApplicationController
  skip_before_action :verify_csrf_token, only: %i[verify_webhook perform_webhook]

  def verify_webhook
    configuration = Whatsapp::Webhook::Configuration.new(options: params)
    challenge = configuration.verify!

    render plain: challenge, status: :ok
  rescue Whatsapp::Webhook::Configuration::VerificationError, Whatsapp::Webhook::NoChannelError => e
    Rails.logger.error e.message
    log_request

    raise Exceptions::UnprocessableEntity, e.message
  end

  def perform_webhook
    signature = request.headers['X-Hub-Signature-256'].sub('sha256=', '')
    uuid      = params[:callback_url_uuid]
    json      = request.body.read

    begin
      payload = Whatsapp::Webhook::Payload.new(json:, uuid:, signature:)
      payload.process
    rescue Whatsapp::Webhook::Payload::ValidationError => e
      Rails.logger.error e.message
      log_request

      raise Exceptions::UnprocessableEntity, e.message
    rescue Whatsapp::Webhook::Payload::ProcessableError, Whatsapp::Webhook::NoChannelError => e
      # Fail silently, any HTTP status code other than 200 will cause WhatsApp
      # to retry the request

      Rails.logger.error(e.respond_to?(:reason) && e.reason.present? ? "#{e.message}: #{e.reason}" : e.message)
      log_request
    end

    render json: {}, status: :ok
  end

  private

  def log_request
    Rails.logger.error "WhatsApp Webhook: #{request.method} #{request.url}"
    Rails.logger.error "WhatsApp Webhook: Headers: #{request.headers.inspect}"
    Rails.logger.error "WhatsApp Webhook: Params: #{params.inspect}"
    Rails.logger.error "WhatsApp Webhook: Payload: #{request.body.read}"
  end
end
