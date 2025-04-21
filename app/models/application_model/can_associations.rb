# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module ApplicationModel::CanAssociations
  extend ActiveSupport::Concern

=begin

set relations of model based on params

  model = Model.find(1)
  result = model.associations_from_param(params)

returns

  result = true|false

=end

  def associations_from_param(params)

    # special handling for group access association
    {
      groups:    :group_names_access_map=,
      group_ids: :group_ids_access_map=
    }.each do |param, setter|
      next if !params.key?(param)

      map = params[param]
      next if !respond_to?(setter)

      send(setter, map)
    end

    # set relations by id/verify if ref exists
    self.class.reflect_on_all_associations.map do |assoc|
      assoc_name = assoc.name
      next if association_attributes_ignored.include?(assoc_name)

      real_ids = "#{assoc_name[0, assoc_name.length - 1]}_ids"
      real_ids = real_ids.to_sym
      next if !params.key?(real_ids)

      list_of_items = params[real_ids]
      if !params[real_ids].instance_of?(Array)
        list_of_items = [ params[real_ids] ]
      end
      list = []
      list_of_items.each do |item_id|
        next if !item_id

        lookup = assoc.klass.lookup(id: item_id)

        # complain if we found no reference
        if !lookup
          raise Exceptions::UnprocessableEntity, "No value found for '#{assoc_name}' with id #{item_id.inspect}"
        end

        list.push item_id
      end

      next if Array(list).sort == Array(send(real_ids)).sort

      send(:"#{real_ids}=", list)
      self.updated_at = Time.zone.now
    end

    # set relations by name/lookup
    self.class.reflect_on_all_associations.map do |assoc|
      assoc_name = assoc.name
      next if association_attributes_ignored.include?(assoc_name)

      real_ids = "#{assoc_name[0, assoc_name.length - 1]}_ids"
      next if !respond_to?(real_ids)

      real_values = "#{assoc_name[0, assoc_name.length - 1]}s"
      real_values = real_values.to_sym
      next if !respond_to?(real_values)
      next if !params[real_values]

      if params[real_values].instance_of?(String) || params[real_values].instance_of?(Integer) || params[real_values].instance_of?(Float)
        params[real_values] = [params[real_values]]
      end
      next if !params[real_values].instance_of?(Array)

      list = []
      class_object = assoc.klass
      params[real_values].each do |value|
        next if value.blank?

        lookup = nil
        if class_object == User
          if !lookup
            lookup = class_object.lookup(login: value)
          end
          if !lookup
            lookup = class_object.lookup(email: value)
          end
        else
          lookup = class_object.lookup(name: value)
        end

        # complain if we found no reference
        if !lookup
          raise Exceptions::UnprocessableEntity, "No lookup value found for '#{assoc_name}': #{value.inspect}"
        end

        list.push lookup.id
      end

      next if Array(list).sort == Array(send(real_ids)).sort

      send(:"#{real_ids}=", list)
      self.updated_at = Time.zone.now
    end
  end

=begin

get relations of model based on params

  model = Model.find(1)
  attributes = model.attributes_with_association_ids

returns

  hash with attributes and association ids

=end

  def attributes_with_association_ids
    key = "#{self.class}::aws::#{id}"
    cache = Rails.cache.read(key)
    return filter_unauthorized_attributes(cache) if cache && cache['updated_at'] == try(:updated_at)

    attributes = self.attributes
    relevant   = %i[has_and_belongs_to_many has_many]
    eager_load = []
    pluck      = []
    keys       = []
    self.class.reflect_on_all_associations.each do |assoc|
      next if relevant.exclude?(assoc.macro)

      assoc_name = assoc.name
      next if association_attributes_ignored.include?(assoc_name)

      eager_load.push(assoc_name)
      pluck.push(Arel.sql("#{ActiveRecord::Base.connection.quote_table_name(assoc.table_name)}.id AS #{ActiveRecord::Base.connection.quote_table_name(assoc_name)}"))
      keys.push("#{assoc_name.to_s.singularize}_ids")
    end

    if eager_load.present?
      ids = self.class.eager_load(eager_load)
                .where(id: id)
                .pluck(*pluck)

      if keys.size > 1
        values = ids.transpose.map { |x| x.compact.uniq }
        attributes.merge!(keys.zip(values).to_h)
      else
        attributes[ keys.first ] = ids.compact
      end
    end

    # special handling for group access associations
    if respond_to?(:group_ids_access_map)
      attributes['group_ids'] = send(:group_ids_access_map)
    end

    filter_attributes(attributes)

    Rails.cache.write(key, attributes)
    filter_unauthorized_attributes(attributes)
  end

=begin

get relation name of model based on params

  model = Model.find(1)
  attributes = model.attributes_with_association_names

returns

  hash with attributes, association ids, association names and relation name

=end

  def attributes_with_association_names(empty_keys: false)

    # get relations
    attributes = attributes_with_association_ids
    self.class.reflect_on_all_associations.map do |assoc|
      next if !respond_to?(assoc.name)
      next if association_attributes_ignored.include?(assoc.name)

      ref = send(assoc.name)
      if empty_keys
        attributes[assoc.name.to_s] = nil
      end
      next if !ref

      if ref.respond_to?(:first)
        attributes[assoc.name.to_s] = []
        ref.each do |item|
          if item[:login]
            attributes[assoc.name.to_s].push item[:login]
            next
          end
          next if !item[:name]

          attributes[assoc.name.to_s].push item[:name]
        end
        if ref.count.positive? && attributes[assoc.name.to_s].blank?
          attributes.delete(assoc.name.to_s)
        end
        next
      end
      if ref[:login]
        attributes[assoc.name.to_s] = ref[:login]
        next
      end
      next if !ref[:name]

      attributes[assoc.name.to_s] = ref[:name]
    end

    # special handling for group access associations
    if respond_to?(:group_names_access_map)
      attributes['groups'] = send(:group_names_access_map)
    end

    # fill created_by/updated_by
    {
      'created_by_id' => 'created_by',
      'updated_by_id' => 'updated_by',
    }.each do |source, destination|
      next if !attributes[source]

      user = User.lookup(id: attributes[source])
      next if !user

      attributes[destination] = user.login
    end

    filter_attributes(attributes)
    filter_unauthorized_attributes(attributes)
  end

  def filter_attributes(attributes)
    # remove forbidden attributes
    attributes.except!('password', 'token', 'tokens', 'token_ids')
  end

  # overwrite this method in derived classes to filter attributes, e.g. app/models/user/assets.rb
  def filter_unauthorized_attributes(attributes)
    attributes
  end

=begin

reference if association id check

  model = Model.find(123)
  attributes = model.association_id_validation('attribute_id', value)

returns

  true | false

=end

  def association_id_validation(attribute_id, value)
    return true if value.nil?

    attributes.each_key do |key|
      next if key != attribute_id

      # check if id is assigned
      next if !key.end_with?('_id')

      key_short = key.chomp('_id')

      self.class.reflect_on_all_associations.map do |assoc|
        next if assoc.name.to_s != key_short

        item = assoc.class_name.constantize
        return false if !item.respond_to?(:find_by)

        ref_object = item.find_by(id: value)
        return false if !ref_object

        return true
      end
    end
    true
  end

  private

  def association_attributes_ignored
    @association_attributes_ignored ||= self.class.instance_variable_get(:@association_attributes_ignored) || []
  end

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

serve method to ignore model attribute associations

class Model < ApplicationModel
  include AssociationConcern
  association_attributes_ignored :users
end

=end

    def association_attributes_ignored(*attributes)
      @association_attributes_ignored ||= []
      @association_attributes_ignored |= attributes
    end

=begin

do name/login/email based lookup for associations

  params = {
    login: 'some login',
    firstname: 'some firstname',
    lastname: 'some lastname',
    email: 'some email',
    organization: 'some organization',
    roles: ['Agent', 'Admin'],
  }

  attributes = Model.association_name_to_id_convert(params)

returns

  attributes = params # params with possible lookups

  attributes = {
    login: 'some login',
    firstname: 'some firstname',
    lastname: 'some lastname',
    email: 'some email',
    organization_id: 123,
    role_ids: [2,1],
  }

=end

    def association_name_to_id_convert(params)

      if params.respond_to?(:permit!)
        params = params.permit!.to_h
      end

      data = {}
      params.each do |key, value|
        data[key.to_sym] = value
      end

      available_attributes = attribute_names
      reflect_on_all_associations.map do |assoc|

        assoc_name = assoc.name
        value      = data[assoc_name]
        next if !value # next if we do not have a value

        ref_name = "#{assoc_name}_id"

        # handle _id values
        if available_attributes.include?(ref_name) # if we do have an _id attribute
          next if data[ref_name.to_sym] # next if we have already the _id filled

          # get association class and do lookup
          class_object = assoc.klass
          lookup = nil
          if class_object == User
            if !value.instance_of?(String)
              raise Exceptions::UnprocessableEntity, "String is needed as ref value #{value.inspect} for '#{assoc_name}'"
            end

            if !lookup
              lookup = class_object.lookup(login: value)
            end
            if !lookup
              lookup = class_object.lookup(email: value)
            end
          else
            lookup = class_object.lookup(name: value)
          end

          # complain if we found no reference
          if !lookup
            raise Exceptions::UnprocessableEntity, "No lookup value found for '#{assoc_name}': #{value.inspect}"
          end

          # release data value
          data.delete(assoc_name)

          # remember id reference
          data[ref_name.to_sym] = lookup.id
          next
        end

        next if !value.instance_of?(Array)
        next if value.blank?
        next if !value[0].instance_of?(String)

        # handle _ids values
        next if !assoc_name.to_s.end_with?('s')

        ref_names = "#{assoc_name.to_s.chomp('s')}_ids"
        generic_object_tmp = new
        next if !generic_object_tmp.respond_to?(ref_names) # if we do have an _ids attribute
        next if data[ref_names.to_sym] # next if we have already the _ids filled

        # get association class and do lookup
        class_object = assoc.klass
        lookup_ids = []
        value.each do |item|
          next if item.blank?

          lookup = nil
          if class_object == User
            if !item.instance_of?(String)
              raise Exceptions::UnprocessableEntity, "String is needed in array ref as ref value #{value.inspect} for '#{assoc_name}'"
            end

            if !lookup
              lookup = class_object.lookup(login: item)
            end
            if !lookup
              lookup = class_object.lookup(email: item)
            end
          else
            lookup = class_object.lookup(name: item)
          end

          # complain if we found no reference
          if !lookup
            raise Exceptions::UnprocessableEntity, "No lookup value found for '#{assoc_name}': #{item.inspect}"
          end

          lookup_ids.push lookup.id
        end

        # release data value
        data.delete(assoc_name)

        # remember id reference
        data[ref_names.to_sym] = lookup_ids
      end

      data
    end
  end
end
