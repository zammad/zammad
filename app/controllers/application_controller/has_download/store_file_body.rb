# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Deliberately neither responds to #to_path nor #to_ary, so Rack::Sendfile and
#   Rack::ETag pass it through instead of buffering the whole file.
class ApplicationController::HasDownload::StoreFileBody
  attr_reader :store_file

  def initialize(store_file)
    @store_file = store_file
  end

  def each
    client_error = nil

    store_file.stream do |chunk|
      yield chunk
    rescue => e
      client_error = e
      raise
    end
  rescue => e
    # Errors while writing to the client, like a disconnect, are no storage failures.
    Rails.logger.error "Streaming of Store::File #{store_file.id} failed: #{e.message}" if !e.equal?(client_error)
    raise
  end
end
