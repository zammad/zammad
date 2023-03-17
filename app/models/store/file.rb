# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Store < ApplicationModel
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
      sha = checksum(data)

      file = Store::File.find_by(sha: sha)
      if file.nil?

        # load backend based on config
        adapter_name = Setting.get('storage_provider') || 'DB'
        if !adapter_name
          raise __("The setting 'storage_provider' was not configured.")
        end

        adapter = "Store::Provider::#{adapter_name}".constantize
        adapter.add(data, sha)
        file = Store::File.create(
          provider: adapter_name,
          sha:      sha,
        )

        # verify
        if verify
          read_data = adapter.get(sha)
          read_sha = checksum(read_data)
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
      "Store::Provider::#{provider}".constantize.get(sha)
    end

=begin

file system check of store, check data and sha (in case fix it)

  Store::File.verify

read each file which should be in backend and verify against sha hash

in case of fixing sha hash use:

  Store::File.verify(true)

=end

    def self.verify(fix_it = nil)
      success = true
      Store::File.find_each(batch_size: 10) do |item|
        sha = checksum(item.content)
        logger.info "CHECK: Store::File.find(#{item.id})"
        next if sha == item.sha

        success = false
        logger.error "DIFF: sha diff of Store::File.find(#{item.id}) current:#{sha}/db:#{item.sha}/provider:#{item.provider}"
        store = Store.find_by(store_file_id: item.id)
        logger.error "STORE: #{store.inspect}"
        item.update_attribute(:sha, sha) if fix_it # rubocop:disable Rails/SkipsModelValidations
      end
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
      adapter_source = "Store::Provider::#{source}".constantize
      adapter_target = "Store::Provider::#{target}".constantize

      Store::File.where(provider: source).find_each(batch_size: 10) do |item|
        adapter_target.add(item.content, item.sha)
        item.update_attribute(:provider, target) # rubocop:disable Rails/SkipsModelValidations
        adapter_source.delete(item.sha)

        logger.info "Moved file #{item.sha} from #{source} to #{target}"

        sleep delay if delay
      end

      true
    end

=begin

generate a checksum for the given content

  Store::File.checksum(binary_data)

=end

    def self.checksum(content)
      Digest::SHA256.hexdigest(content)
    end

    private

    def destroy_provider
      "Store::Provider::#{provider}".constantize.delete(sha)
    end
  end
end
