# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ChannelsAdmin::MicrosoftGraphController < ChannelsAdmin::BaseController
  include CanXoauth2EmailChannel

  def area
    'MicrosoftGraph::Account'.freeze
  end

  def external_credential_name
    'microsoft_graph'.freeze
  end

  def folders
    channel = Channel.find_by(id: params[:id], area:)
    raise Exceptions::UnprocessableEntity, __('Could not find the channel.') if channel.nil?

    channel_mailbox = channel.options.dig('inbound', 'options', 'shared_mailbox') || channel.options.dig('inbound', 'options', 'user')
    raise Exceptions::UnprocessableEntity, __('Could not identify the channel mailbox.') if channel_mailbox.nil?

    channel.refresh_xoauth2!(force: true)

    graph = ::MicrosoftGraph.new access_token: channel.options.dig('auth', 'access_token'), mailbox: channel_mailbox

    begin
      folders = graph.get_message_folders_tree
    rescue ::MicrosoftGraph::ApiError => e
      error = {
        message: e.message,
        code:    e.error_code,
      }
    end

    render json: { folders:, error: }
  end
end
