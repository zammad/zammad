# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module ApplicationModel::CanLookup
  extend ActiveSupport::Concern

  class_methods do

=begin

lookup model from cache (if exists) or retrieve it from db, id, name, login or email possible

  result = Model.lookup(id: 123)
  result = Model.lookup(name: 'some name')
  result = Model.lookup(login: 'some login')
  result = Model.lookup(email: 'some login')

returns

  result = model # with all attributes

=end

    def lookup(**attr)
      raise ArgumentError, "Multiple lookup attributes given (#{attr.keys.join(', ')}), only support (#{lookup_keys.join(', ')})" if attr.many?

      attr.transform_keys!(&:to_sym).slice!(*lookup_keys)
      raise ArgumentError, "Valid lookup attribute required (#{lookup_keys.join(', ')})" if attr.empty?

      cache_get(attr.values.first) || find_and_save_to_cache_by(attr)
    end

=begin

return possible lookup keys for model

  result = Model.lookup_keys

returns

  [:id, :name] # or, for users: [:id, :login, :email]

=end

    def lookup_keys
      @lookup_keys ||= %i[id name login email number] & attribute_names.map(&:to_sym)
    end

    private

    def find_and_save_to_cache_by(args)
      attribute    = args.keys.first
      lookup_value = args.values.first.to_s

      # rollbacks can invalidate cache entry
      # therefore we don't write it
      if ActiveRecord::Base.connection.transaction_open?
        result = find_by(attribute => lookup_value)
        # enforce case-sensitivity on MySQL
        result = nil if !key_sensitive_match?(result, attribute, lookup_value)
      else
        # get the record via an `FOR UPDATE` DB lock inside of
        # a transaction to ensure that we don't write obsolete
        # data into the cache
        transaction do
          result = lock.find_by(attribute => lookup_value)
          # enforce case-sensitivity on MySQL
          if key_sensitive_match?(result, attribute, lookup_value)
            # cache only if we got a key-sensitive match
            cache_set(lookup_value, result)
          else
            # no key-sensitive match - no result
            result = nil
          end
        end
      end

      result
    end

    def key_sensitive_match?(record, attribute, lookup_value)
      return false if record.blank?
      return true if type_for_attribute(attribute.to_s).type != :string

      record[attribute] == lookup_value
    end

  end
end
