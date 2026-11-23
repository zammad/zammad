# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Collects documents of one index and sends them to Elasticsearch in bulk requests.
#
#   bulk = SearchIndexBackend::Bulk.new('Ticket')
#   bulk.add(some_data_object)
#   bulk.add(another_data_object)
#   bulk.flush
#
#   bulk.failed_ids # => ids of the documents which were not indexed, e.g. [123]
class SearchIndexBackend::Bulk
  # Documents with attachments can be large, so the size and not only the number of documents limits a request.
  MAX_REQUEST_SIZE = 20.megabytes

  # Elasticsearch answers 429 or 503 when it is short of memory, its queue is full or it is starting. Waiting helps
  # then, sending the documents one by one right away does not.
  BUSY_TRIES = 5
  BUSY_DELAY = 15.seconds

  attr_reader :type, :ids, :entries, :size, :failed_ids

  def initialize(type)
    @type       = type
    @failed_ids = []

    clear
  end

  def add(document)
    entry = "#{{ index: { _id: document['id'] } }.to_json}\n#{document.to_json}\n"

    flush if size + entry.bytesize > MAX_REQUEST_SIZE

    ids << document['id']
    entries << entry
    @size = size + entry.bytesize
  end

  def flush
    return if ids.empty?

    failed_ids.concat(perform)
    clear
  end

  private

  def clear
    @ids     = []
    @entries = []
    @size    = 0
  end

  def perform
    url = SearchIndexBackend.build_url(type:, action: '_bulk', with_document_type: false)
    return [] if url.blank?

    pending = ids.zip(entries).to_h
    failed  = []

    BUSY_TRIES.times do |try|
      states = request(url, pending)
      failed.concat(states.select { |_id, state| state == :failed }.keys)
      pending = pending.slice(*states.select { |_id, state| state == :busy }.keys)
      break if pending.empty? || try == BUSY_TRIES - 1

      Rails.logger.warn "Elasticsearch is busy, #{pending.size} #{type} documents are sent again in #{BUSY_DELAY.to_i} seconds."
      sleep BUSY_DELAY
    end

    failed + pending.keys
  end

  # Returns for the id of each document whether it is :indexed, :failed, or :busy if sending it again can help.
  def request(url, pending)
    states(SearchIndexBackend.make_request(url, data: pending.values.join, method: :post, request_type: :reindex), pending.keys)
  rescue => e
    Rails.logger.error "Unable to send bulk request with #{pending.size} #{type} documents to Elasticsearch: #{e.inspect}"
    pending.keys.index_with(:busy)
  end

  def states(response, ids)
    items = response.data['items'] if response.success? && response.data.is_a?(Hash)

    return ids.zip(items).to_h { |id, item| [id, state(item)] } if items.is_a?(Array) && items.size == ids.size

    Rails.logger.error "Unable to send bulk request with #{ids.size} #{type} documents to Elasticsearch: #{response.error.presence || response.code}"
    ids.index_with(busy?(response.code) ? :busy : :failed)
  end

  def state(item)
    status = item['index']['status'] if item.is_a?(Hash) && item['index'].is_a?(Hash)
    return :indexed if status.is_a?(Integer) && status.between?(200, 299)

    busy?(status) ? :busy : :failed
  end

  def busy?(code)
    %w[429 503].include?(code.to_s)
  end
end
