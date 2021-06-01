# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Integration::SMIMEController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

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
    render json: SMIMECertificate.all
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

    items = string.scan(%r{.+?-+END(?: TRUSTED)? CERTIFICATE-+}mi).each_with_object([]) do |cert, result|
      result << SMIMECertificate.create!(public_key: cert)
    end

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

    raise "Parameter 'data' or 'file' required." if string.blank?

    private_key = OpenSSL::PKey.read(string, params[:secret])
    modulus     = private_key.public_key.n.to_s(16)

    certificate = SMIMECertificate.find_by(modulus: modulus)

    raise Exceptions::UnprocessableEntity, 'Unable for find certificate for this private key.' if !certificate

    certificate.update!(private_key: string, private_key_secret: params[:secret])

    render json: {
      result: 'ok',
    }
  rescue => e
    unprocessable_entity(e)
  end

  def search
    result = {
      type: 'S/MIME',
    }

    result[:encryption] = article_encryption(params[:article])
    result[:sign]       = article_sign(params[:ticket])

    render json: result
  end

  def article_encryption(article)
    result = {
      success: false,
      comment: 'no recipient found',
    }

    return result if article.blank?
    return result if article[:to].blank? && article[:cc].blank?

    recipient  = [ article[:to], article[:cc] ].compact.join(',').to_s
    recipients = []
    begin
      list = Mail::AddressList.new(recipient)
      list.addresses.each do |address|
        recipients.push address.address
      end
    rescue # rubocop:disable Lint/SuppressedException
    end

    return result if recipients.blank?

    begin
      certs = SMIMECertificate.for_recipipent_email_addresses!(recipients)

      if certs
        if certs.any?(&:expired?)
          result[:success] = false
          result[:comment] = "certificates found for #{recipients.join(',')} but expired"
        else
          result[:success] = true
          result[:comment] = "certificates found for #{recipients.join(',')}"
        end
      end
    rescue => e
      result[:comment] = e.message
    end

    result
  end

  def article_sign(ticket)
    result = {
      success: false,
      comment: 'certificate not found',
    }

    return result if ticket.blank? || !ticket[:group_id]

    group = Group.find_by(id: ticket[:group_id])
    return result if !group

    email_address = group.email_address
    begin
      list = Mail::AddressList.new(email_address.email)
      from = list.addresses.first.to_s
      cert = SMIMECertificate.for_sender_email_address(from)
      if cert
        if cert.expired?
          result[:success] = false
          result[:comment] = "certificate for #{email_address.email} found but expired"
        else
          result[:success] = true
          result[:comment] = "certificate for #{email_address.email} found"
        end
      else
        result[:success] = false
        result[:comment] = "no certificate for #{email_address.email} found"
      end
    rescue => e
      result[:comment] = e.message
    end

    result
  end

end
