# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class MicrosoftGraph
  BASE_URL = 'https://graph.microsoft.com/v1.0/'.freeze

  attr_reader :bearer_token, :mailbox

  def initialize(access_token:, mailbox:)
    super()
    @bearer_token = access_token
    @mailbox      = mailbox
  end

  def send_message(mail)
    headers = { 'Content-Type' => 'text/plain' }
    encoded = Base64.strict_encode64(mail.to_s)
    options = { headers:, send_as_raw_body: encoded }
    make_request('sendMail', method: :post, json: false, options:)
  end

  def store_mocked_message(params, folder_id: 'inbox')
    make_request("mailFolders/#{folder_id}/messages", method: :post, params:)
  end

  def list_messages(unread_only: false, per_page: 1000, follow_pagination: true, folder_id: nil, select: 'id')
    path = 'messages/?$count=true&$orderby=receivedDateTime ASC'

    path += "&$select=#{select}"
    path += "&top=#{per_page}"

    filters = []

    filters << 'isRead eq false' if unread_only
    filters << "parentFolderId eq '#{folder_id || 'inbox'}'"

    if filters.any?
      path += "&$filter=(#{filters.join(' AND ')})"
    end

    make_paginated_request(path, follow_pagination:)
  end

  def create_message_folder(name, parent_folder_id: nil)
    path = if parent_folder_id.present?
             "mailFolders/#{parent_folder_id}/childFolders"
           else
             'mailFolders'
           end

    params = { displayName: name }

    make_request(path, method: :post, params:)
  end

  def get_message_folder_details(id)
    make_request("mailFolders/#{id}")
  end

  def delete_message_folder(id)
    make_request("mailFolders/#{id}", method: :delete)
  end

  def get_message_folders_tree(parent = nil)
    path = if parent.present?
             "mailFolders/#{parent}/childFolders"
           else
             'mailFolders'
           end

    make_paginated_request("#{path}?$expand=childFolders($top=9999)&$top=9999")
      .fetch(:items, [])
      .map do |elem|
        {
          id:           elem[:id],
          displayName:  elem[:displayName],
          childFolders: elem[:childFolders].map do |expanded_elem|
            if expanded_elem[:childFolderCount].positive?
              expanded_folders = get_message_folders_tree(expanded_elem[:id])
            end

            {
              id:           expanded_elem[:id],
              displayName:  expanded_elem[:displayName],
              childFolders: expanded_folders || []
            }
          end
        }
      end
  end

  def get_message_basic_details(message_id)
    result = make_request("messages/#{message_id}/?$expand=singleValueExtendedProperties($filter=Id%20eq%20'LONG%200x0E08')&$select=internetMessageHeaders")

    size = result.fetch(:singleValueExtendedProperties)
      .find { |elem| elem[:id] == 'Long 0xe08' }
      &.dig(:value)
      &.to_i

    headers = headers_to_hash result.fetch(:internetMessageHeaders, {})

    { headers:, size: }
  end

  def get_raw_message(message_id)
    make_request("messages/#{message_id}/$value", json: false)
  end

  def mark_message_as_read(message_id)
    make_request("messages/#{message_id}", method: :patch, params: { isRead: true })
  end

  def delete_message(message_id)
    make_request("messages/#{message_id}", method: :delete)
  end

  private

  def make_request(path, method: :get, json: true, params: {}, options: {})
    options[:bearer_token] = bearer_token
    options[:json] = json

    uri = URI(path).host.present? ? path : "#{BASE_URL}#{mailbox_path}#{path}"

    response = UserAgent.send(method, uri, params, options)

    if !response.success?
      error_details = if response&.body&.start_with?('{')
                        JSON.parse(response.body)['error']
                      else
                        {
                          code:    response.code,
                          message: response.body || response.error,
                        }
                      end

      raise ApiError, error_details
    end

    if json && (data = response.data.presence)
      return data.with_indifferent_access
    end

    response.body
  end

  PAGINATED_MAX_LOOPS = 25

  def make_paginated_request(path, follow_pagination: true, **)
    response = make_request(path, **)

    total_count = response[:'@odata.count']

    return { total_count:, items: response.fetch(:value) } if !follow_pagination

    received = [response]

    while (pagination_link = response['@odata.nextLink'])
      response = make_request(pagination_link)
      received << response

      if received.count > PAGINATED_MAX_LOOPS # rubocop:disable Style/Next
        error = {
          code:    'X-Zammad-MsGraphEndlessLoop',
          message: "Microsoft Graph API paginated response caused a permanenet loop: #{path}"
        }

        raise ApiError, error
      end
    end

    items = received.flat_map { |elem| elem.fetch(:value) }

    { total_count:, items: }
  end

  def headers_to_hash(input)
    input.each_with_object({}.with_indifferent_access) do |elem, memo|
      memo[elem[:name]] = elem[:value]
    end
  end

  def mailbox_path
    "users/#{mailbox}/"
  end
end
