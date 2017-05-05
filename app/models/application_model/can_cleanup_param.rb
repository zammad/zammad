# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module ApplicationModel::CanCleanupParam
  extend ActiveSupport::Concern

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

remove all not used model attributes of params

  result = Model.param_cleanup(params)

  for object creation, ignore id's

  result = Model.param_cleanup(params, true)

returns

  result = params # params with valid attributes of model

=end

    def param_cleanup(params, new_object = false)

      if params.respond_to?('permit!')
        params.permit!
      end

      if params.nil?
        raise ArgumentError, "No params for #{self}!"
      end

      data = {}
      params.each { |key, value|
        data[key.to_sym] = value
      }

      # ignore id for new objects
      if new_object && params[:id]
        data.delete(:id)
      end

      # only use object attributes
      clean_params = {}
      new.attributes.each { |attribute, _value|
        next if !data.key?(attribute.to_sym)

        # check reference records, referenced by _id attributes
        reflect_on_all_associations.map { |assoc|
          class_name = assoc.options[:class_name]
          next if !class_name
          name = "#{assoc.name}_id".to_sym
          next if !data.key?(name)
          next if data[name].blank?
          next if assoc.klass.lookup(id: data[name])
          raise ArgumentError, "Invalid value for param '#{name}': #{data[name].inspect}"
        }
        clean_params[attribute.to_sym] = data[attribute.to_sym]
      }

      # we do want to set this via database
      filter_unused_params(clean_params)
    end

    private

=begin

remove all not used params of object (per default :updated_at, :created_at, :updated_by_id and :created_by_id)

  result = Model.filter_unused_params(params)

returns

  result = params # params without listed attributes

=end

    def filter_unused_params(data)

      # we do want to set this via database
      [:action, :controller, :updated_at, :created_at, :updated_by_id, :created_by_id, :updated_by, :created_by].each { |key|
        data.delete(key)
      }

      data
    end
  end
end
