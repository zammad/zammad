# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Store
  module Provider
    class DB < ApplicationModel
      self.table_name = 'store_provider_dbs'

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
