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
      attr.transform_keys!(&:to_sym).slice!(*lookup_keys)
      raise ArgumentError, "Valid lookup attribute required (#{lookup_keys.join(', ')})" if attr.empty?
      raise ArgumentError, "Multiple lookup attributes given (#{attr.keys.join(', ')})" if attr.many?

      record   = cache_get(attr.values.first)
      record ||= find_and_save_to_cache_by(attr)
    end

    private

    def lookup_keys
      @lookup_keys ||= %i[id name login email number] & attribute_names.map(&:to_sym)
    end

    def find_and_save_to_cache_by(attr)
      if !Rails.application.config.db_case_sensitive && string_key?(attr.keys.first)
        where(attr).find { |r| r[attr.keys.first] == attr.values.first }
      else
        find_by(attr)
      end.tap { |r| cache_set(attr.values.first, r) }
    end

    def string_key?(key)
      type_for_attribute(key.to_s).type == :string
    end
  end
end
