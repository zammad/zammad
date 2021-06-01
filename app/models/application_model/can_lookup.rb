# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

    def find_and_save_to_cache_by(attr)
      record = find_by(attr)
      return nil if string_key?(attr.keys.first) && (record&.send(attr.keys.first) != attr.values.first.to_s) # enforce case-sensitivity on MySQL
      return record if ActiveRecord::Base.connection.transaction_open? # rollbacks can invalidate cache entries

      cache_set(attr.values.first, record)
      record
    end

    def string_key?(key)
      type_for_attribute(key.to_s).type == :string
    end

  end
end
