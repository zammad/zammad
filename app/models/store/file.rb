# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Store < ApplicationModel
  class File < ApplicationModel
    include ApplicationLib

    after_destroy :destroy_in_provider
    has_many :stores, foreign_key: :store_file_id, dependent: :destroy, inverse_of: :store_file

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

        adapter = provider_class(adapter_name)
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
      @content ||= provider_class.get(sha)
    end

=begin

file system check of store, check data and sha (in case fix it)

  Store::File.verify

read each file which should be in backend and verify against sha hash

in case of fixing sha hash use:

  Store::File.verify(true)

=end

    def self.verify(fix_it = false)
      Store::File.find_each(batch_size: 10).reduce(true) do |memo, item|
        logger.info "CHECK: Store::File.find(#{item.id})"

        next memo if item.checksum_valid?

        logger.error "DIFF: SHA diff of Store::File.find(#{item.id}) current:#{item.content_checksum}/db:#{item.sha}/provider:#{item.provider}"
        logger.error "STORES: #{item.stores.inspect}"

        item.update_checksum! if fix_it

        false
      rescue => e
        logger.error { e.message }

        false
      end
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
      adapter_source = provider_class(source)
      adapter_target = provider_class(target)

      succeeded = true

      Store::File.where(provider: source).find_each(batch_size: 10) do |item|
        begin
          adapter_target.add(item.content, item.sha)
          item.update_attribute(:provider, target) # rubocop:disable Rails/SkipsModelValidations
          adapter_source.delete(item.sha)
        rescue => e
          succeeded = false
          logger.error "File #{item.sha} could not be moved from #{source} to #{target}: #{e.message}"
          next
        end

        logger.info "Moved file #{item.sha} from #{source} to #{target}"

        sleep delay if delay
      end

      succeeded
    end

=begin

generate a checksum for the given content

  Store::File.checksum(binary_data)

=end

    def self.checksum(content)
      Digest::SHA256.hexdigest(content)
    end

    def checksum_valid?
      sha == content_checksum
    end

    def update_checksum!
      return if checksum_valid?

      new_sha_file = self.class.where(sha: content_checksum).where.not(id: id).first

      if !new_sha_file
        ActiveRecord::Base.transaction do
          update! sha: content_checksum

          provider_class.change_checksum(sha_previously_was, sha)

          stores.find_each do |elem|
            elem.update! size: content_size
          end

        end
        return
      end

      if !new_sha_file.checksum_valid?
        raise "CONFLICT: file with SHA #{new_sha_file.sha} exists but its content does not match!"
      end

      ActiveRecord::Base.transaction do
        stores.find_each do |elem|
          elem.update! store_file: new_sha_file, size: new_sha_file.content_size
        end

        destroy!
      end
    end

    def content_checksum
      @content_checksum ||= self.class.checksum(content)
    end

    def content_size
      content.to_s.bytesize
    end

    def self.provider_class(provider)
      "Store::Provider::#{provider}".constantize
    end

    private

    def destroy_in_provider
      provider_class.delete(sha)
    end

    def provider_class
      self.class.provider_class(provider)
    end
  end
end
