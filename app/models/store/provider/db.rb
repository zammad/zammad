# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Store
  module Provider
    class DB < ApplicationModel
      self.table_name = 'store_provider_dbs'

      # Bigger than the other providers' chunks: PostgreSQL decompresses a
      #   compressed value up to the requested offset for every chunk.
      CHUNK_SIZE = 4.megabytes

      def self.add(data, sha)
        Store::Provider::DB.create(
          data: data,
          sha:  sha,
        )
        true
      end

      def self.get(sha)
        Store::Provider::DB
          .find_by(sha: sha)
          &.data
      end

      def self.stream(sha)
        total = bytesize(sha)
        return if !total

        offset = 0
        while offset < total
          # Every chunk is a distinct query, the query cache would keep them all until the response is done.
          chunk = uncached { where(sha:).pick(Arel.sql(sanitize_sql_array(['substring(data FROM ? FOR ?)', offset + 1, CHUNK_SIZE]))) }
          # Not #blank?, which is also true for a chunk of whitespace only.
          raise "Content of #{sha} ended after #{offset} of #{total} bytes." if chunk.nil? || chunk.bytesize.zero?

          yield chunk
          offset += chunk.bytesize
        end
      end

      def self.bytesize(sha)
        where(sha:).pick(Arel.sql('octet_length(data)'))
      end

      def self.delete(sha)
        Store::Provider::DB.where(sha: sha).destroy_all
        true
      end

      def self.change_checksum(old_sha, new_sha)
        Store::Provider::DB
          .find_by(sha: old_sha)
          &.update(sha: new_sha)
      end
    end
  end
end
