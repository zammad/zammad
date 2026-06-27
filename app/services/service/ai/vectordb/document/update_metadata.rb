# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB::Document
  # Updates the metadata field on all existing chunk vectors for a document without
  # re-chunking or re-embedding. Use when only metadata changed (e.g. category, visibility).
  # @return [Integer] the number of documents matched (0 means nothing was indexed for this record)
  class UpdateMetadata < Service::AI::VectorDB::Base
    attr_reader :object_name, :o_id, :metadata

    def initialize(object_name:, object_id:, metadata:)
      @object_name = object_name
      @o_id        = object_id
      @metadata    = metadata
    end

    def execute
      response = ai_vector_db.update_metadata(object_id: o_id, object_name:, metadata:)
      response['total'].to_i
    end
  end
end
