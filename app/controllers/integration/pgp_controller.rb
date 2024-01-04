# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Integration::PGPController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def key_list
    model_index_render(PGPKey, params)
  end

  def key_show
    model_show_render(PGPKey, params)
  end

  def key_download
    key = PGPKey.find(params[:id])

    if %w[1 true].include?(params[:secret])
      raise Exceptions::UnprocessableEntity, __('This is not a private PGP key.') if !key.secret

      return send_data(
        key.key,
        filename:    "#{key.fingerprint}.asc",
        type:        'text/plain',
        disposition: 'attachment'
      )
    end

    send_data(
      export(key),
      filename:    "#{key.fingerprint}.pub.asc",
      type:        'text/plain',
      disposition: 'attachment'
    )
  end

  def key_add
    PGPKey.params_cleanup! params

    model_create_render(PGPKey, params)
  end

  def key_delete
    model_destroy_render(PGPKey, params)
  end

  def status
    if !SecureMailing::PGP.required_version?
      error = __('gpg (GnuPG) 2.2.0 or newer is required')
    end

    render json: { error: error }.compact
  end

  def search
    security_options = SecureMailing::PGP::SecurityOptions.new(ticket: params[:ticket], article: params[:article]).process

    result = {
      type:       'PGP',
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

  def export(key)
    SecureMailing::PGP::Tool.new.with_private_keyring do |pgp_tool|
      pgp_tool.import(key.key)
      pgp_tool.export(key.fingerprint).stdout
    end
  end
end
