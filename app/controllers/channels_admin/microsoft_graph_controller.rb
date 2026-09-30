# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
    raise Exceptions::UnprocessableContent, __('Could not find the channel.') if channel.nil?

    channel_mailbox = channel.options.dig('inbound', 'options', 'shared_mailbox') || channel.options.dig('inbound', 'options', 'user')
    raise Exceptions::UnprocessableContent, __('Could not identify the channel mailbox.') if channel_mailbox.nil?

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

  private

  def inbound_prepare_channel(channel)
    super

    posted_options = params[:options] || {}
    %w[post_import_action move_to_folder_id].each do |key|
      next if posted_options[key].nil?

      channel.options[:inbound][:options][key] = posted_options[key]
    end

    options = channel.options[:inbound][:options]
    if posted_options[:post_import_action].nil? && !posted_options[:keep_on_server].nil? && options[:post_import_action].present?
      options[:post_import_action] = ActiveModel::Type::Boolean.new.cast(posted_options[:keep_on_server]) ? 'mark_read' : 'delete'
    end

    Channel::Driver::MicrosoftGraphInbound.validate_post_import_options!(options)
    options[:keep_on_server] = options[:post_import_action] == 'mark_read' if options[:post_import_action].present?
  end
end
