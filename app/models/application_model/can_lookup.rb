# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

      return find_by(attr) if columns.exclude?('updated_at')

      Rails.cache.fetch("#{self}/#{latest_change}/lookup/#{Digest::MD5.hexdigest(Marshal.dump(attr))}") do
        find_by(attr)
      end
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
  end
end
