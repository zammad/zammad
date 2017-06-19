# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Store
  class File < ApplicationModel
    include ApplicationLib
    after_destroy :destroy_provider

=begin

add new file to store

  store_file_id = Store::File.add(binary_data)

do also verify of written data

  store_file_id = Store::File.add(binary_data, true)

=end

    def self.add(data, verify = true)
      sha = Digest::SHA256.hexdigest(data)

      file = Store::File.find_by(sha: sha)
      if file.nil?

        # load backend based on config
        adapter_name = Setting.get('storage_provider') || 'DB'
        if !adapter_name
          raise 'Missing storage_provider setting option'
        end
        adapter = load_adapter("Store::Provider::#{adapter_name}")
        adapter.add(data, sha)
        file = Store::File.create(
          provider: adapter_name,
          sha: sha,
        )

        # verify
        if verify
          read_data = adapter.get(sha)
          read_sha = Digest::SHA256.hexdigest(read_data)
          if sha != read_sha
            raise "Content not written correctly (provider #{adapter_name})."
          end
        end
      end
      file
    end

=begin

read content of a file

  store = Store::File.find(123)

  store.content # returns binary

=end

    def content
      adapter = self.class.load_adapter("Store::Provider::#{provider}")
      adapter.get(sha)
    end

=begin

file system check of store, check data and sha (in case fix it)

  Store::File.verify

read each file which should be in backend and verify agsinst sha hash

in case of fixing sha hash use:

  Store::File.verify(true)

=end

    def self.verify(fix_it = nil)
      success = true
      file_ids = Store::File.all.pluck(:id)
      file_ids.each { |item_id|
        item = Store::File.find(item_id)
        content = item.content
        sha = Digest::SHA256.hexdigest(content)
        logger.info "CHECK: Store::File.find(#{item.id})"
        next if sha == item.sha
        success = false
        logger.error "DIFF: sha diff of Store::File.find(#{item.id}) current:#{sha}/db:#{item.sha}/provider:#{item.provider}"
        store = Store.find_by(store_file_id: item.id)
        logger.error "STORE: #{store.inspect}"
        if fix_it
          item.update_attribute(:sha, sha)
        end
      }
      success
    end

=begin

move file from one to other provider

move files from file backend to db

  Store::File.move('File', 'DB')

move files from db backend to fs

  Store::File.move('DB', 'File')

nice move to keep system responsive

  Store::File.move('DB', 'File', delay_in_sec) # e. g. 1

=end

    def self.move(source, target, delay = nil)
      adapter_source = load_adapter("Store::Provider::#{source}")
      adapter_target = load_adapter("Store::Provider::#{target}")

      file_ids = Store::File.all.pluck(:id)
      file_ids.each { |item_id|
        item = Store::File.find(item_id)
        next if item.provider == target
        content = item.content

        # add to new provider
        adapter_target.add(content, item.sha)

        # update meta data
        item.update_attribute(:provider, target)

        # remove from old provider
        adapter_source.delete(item.sha)

        logger.info "Moved file #{item.sha} from #{source} to #{target}"

        sleep delay if delay
      }
      true
    end

    private

    def destroy_provider
      adapter = self.class.load_adapter("Store::Provider::#{provider}")
      adapter.delete(sha)
    end
  end
end
