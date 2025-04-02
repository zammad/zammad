# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SSLCertificatesController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    certificates = SSLCertificate.all
    assets       = ApplicationModel::CanAssets.reduce(certificates)

    render json: assets
  end

  def create
    cert = SSLCertificate.create!(cert_params)

    render json: cert.attributes_with_association_ids, status: :created
  end

  def destroy
    SSLCertificate
      .find(params[:id])
      .destroy!

    render json: {
      result: 'ok',
    }
  end

  def download
    cert = SSLCertificate.find params[:id]

    send_data(
      cert.certificate,
      filename:    "#{cert.fingerprint}.crt",
      type:        'text/plain',
      disposition: 'attachment'
    )
  end

  private

  def cert_params
    output = params.permit(:certificate)

    if output[:certificate].blank?
      output[:certificate] = params[:file]&.read&.force_encoding('utf-8')
    end

    output
  end
end
