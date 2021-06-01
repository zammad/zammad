# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
        file = Store::Provider::DB.find_by(sha: sha)
        return if !file

        file.data
      end

      def self.delete(sha)
        Store::Provider::DB.where(sha: sha).destroy_all
        true
      end
    end
  end
end
