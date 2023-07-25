# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Integration::SMIMEController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def certificate_download
    cert = SMIMECertificate.find(params[:id])

    send_data(
      cert.raw,
      filename:    "#{cert.doc_hash}.crt",
      type:        'text/plain',
      disposition: 'attachment'
    )
  end

  def private_key_download
    cert = SMIMECertificate.find(params[:id])

    send_data(
      cert.private_key,
      filename:    "#{cert.doc_hash}.key",
      type:        'text/plain',
      disposition: 'attachment'
    )
  end

  def certificate_list
    all = SMIMECertificate.all.map do |cert|
      cert.attributes.merge({ 'subject_alternative_name' => cert.email_addresses })
    end
    render json: all
  end

  def certificate_delete
    SMIMECertificate.find(params[:id]).destroy!
    render json: {
      result: 'ok',
    }
  end

  def certificate_add
    string = params[:data]
    if string.blank? && params[:file].present?
      string = params[:file].read.force_encoding('utf-8')
    end

    items = SMIMECertificate.create_certificates(string)

    render json: {
      result:   'ok',
      response: items,
    }
  rescue => e
    unprocessable_entity(e)
  end

  def private_key_delete
    SMIMECertificate.find(params[:id]).update!(
      private_key:        nil,
      private_key_secret: nil,
    )

    render json: {
      result: 'ok',
    }
  end

  def private_key_add
    string = params[:data]
    if string.blank? && params[:file].present?
      string = params[:file].read.force_encoding('utf-8')
    end

    raise __("Parameter 'data' or 'file' required.") if string.blank?

    SMIMECertificate.create_certificates(string)
    SMIMECertificate.create_private_keys(string, params[:secret])

    render json: {
      result: 'ok',
    }
  rescue => e
    unprocessable_entity(e)
  end

  def search
    security_options = SecureMailing::SMIME::SecurityOptions.new(ticket: params[:ticket], article: params[:article]).process

    result = {
      type:       'S/MIME',
      encryption: map_result(security_options.encryption),
      sign:       map_result(security_options.signing),
    }

    render json: result
  end

  private

  def map_result(method_result)
    {
      success:             method_result.possible?,
      comment:             method_result.message,
      commentPlaceholders: method_result.message_placeholders,
    }
  end
end
