# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Integration::SMIMEController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def certificate_download
    cert = SMIMECertificate.find(params[:id])

    send_data(
      cert.pem,
      filename:    "#{cert.subject_hash}.crt",
      type:        'text/plain',
      disposition: 'attachment'
    )
  end

  def private_key_download
    cert = SMIMECertificate.find(params[:id])

    send_data(
      cert.private_key,
      filename:    "#{cert.subject_hash}.key",
      type:        'text/plain',
      disposition: 'attachment'
    )
  end

  def certificate_list
    list = SMIMECertificate.all.map { |cert| cert_obj_to_json(cert) }

    render json: list
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

    cert = Certificate::X509::SMIME.parse(string)
    cert.valid_smime_certificate!

    items = SMIMECertificate.create_certificates(string)

    render json: {
      result:   'ok',
      response: items.map { |c| cert_obj_to_json(c) },
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

    private_key = SecureMailing::SMIME::PrivateKey.read(string, params[:secret])
    private_key.valid_smime_private_key!

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

  def cert_obj_to_json(cert)
    info = cert.parsed

    smime_cert = Certificate::X509::SMIME.new(cert.pem)
    usage = [
      smime_cert.signature? ? __('Signature') : nil,
      smime_cert.encryption? ? __('Encryption') : nil,
    ].compact

    {
      id:                       cert.id,
      subject:                  info.subject.to_s,
      doc_hash:                 cert.subject_hash,
      fingerprint:              cert.fingerprint,
      modulus:                  cert.uid,
      not_before_at:            info.not_before,
      not_after_at:             info.not_after,
      raw:                      cert.pem,
      private_key:              cert.private_key,
      private_key_secret:       cert.private_key_secret,
      created_at:               cert.created_at,
      updated_at:               cert.updated_at,
      subject_alternative_name: cert.email_addresses.join(', '),
      usage:                    usage
    }
  end
end
