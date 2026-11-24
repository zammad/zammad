# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The option lists of a form's fields, kept between requests. An entry is found by what its list is built from, so that
#   a change to any of it leads to another entry: none is updated or removed, one that is not asked for anymore expires.
module FormUpdater::OptionCache
  EXPIRES_IN = 1.day

  # Every request and result carries one signature per list, so half of the digest has to do.
  SIGNATURE_LENGTH = 32

  # The signature of a list, which a form that holds the list sends back in place of asking for it again.
  #
  # @param key [Object, nil] what the list is built from, nil for a list that is built on every request
  # @return [String, nil]
  def self.signature(key)
    return if key.nil?

    Digest::SHA256.hexdigest(key.to_json).first(SIGNATURE_LENGTH)
  end

  # @param key [Object, nil] what the list is built from as read so far, nil for a list that is built on every request
  # @param key_source [#call] reads what the list is built from
  # @yieldreturn [Array<Hash>] the options as the form's field takes them
  # @return [Array(Array<Hash>, Object)] the list and the key that stands for it, nil where none does
  def self.fetch(key, key_source, &)
    return [yield, nil] if key.nil?

    kept = Rails.cache.read(cache_key(key))
    return [kept, key] if !kept.nil?

    list, key = build(key_source, &)
    Rails.cache.write(cache_key(key), list, expires_in: EXPIRES_IN) if key

    [list, key]
  end

  # A list is kept under the key of the state it was built from. Read at another time than the list, a key may be of
  #   another state: the list would answer whoever has that state again. So both are read from one snapshot of the
  #   database, past the query cache, which would answer the reads of a request with what it read before.
  #
  # What a key reads elsewhere, like a setting, has no snapshot: there the list has no key where the key reads
  #   differently after the list was built.
  def self.build(key_source)
    ActiveRecord::Base.uncached do
      in_snapshot do
        key  = key_source.call
        list = yield

        [list, (key if key_source.call == key)]
      end
    end
  end

  # A transaction of the caller cannot be given a snapshot anymore, it reads on as it is.
  def self.in_snapshot(&)
    return yield if ActiveRecord::Base.connection.transaction_open?

    ActiveRecord::Base.transaction(isolation: :repeatable_read, &)
  end

  def self.cache_key(key)
    "#{name}::#{signature(key)}"
  end

  private_class_method :build, :in_snapshot, :cache_key
end
