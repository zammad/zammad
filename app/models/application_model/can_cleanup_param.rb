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

      if params.respond_to?(:permit!)
        params = params.permit!.to_h
      end

      if params.nil?
        raise ArgumentError, "No params for #{self}!"
      end

      data = {}
      params.each do |key, value|
        data[key.to_s] = value
      end

      # ignore id for new objects
      if new_object && params[:id]
        data.delete('id')
      end

      # only use object attributes
      clean_params = ActiveSupport::HashWithIndifferentAccess.new
      new.attributes.each_key do |attribute|
        next if !data.key?(attribute)

        # check reference records, referenced by _id attributes
        reflect_on_all_associations.map do |assoc|
          class_name = assoc.options[:class_name]
          next if !class_name
          name = "#{assoc.name}_id"
          next if !data.key?(name)
          next if data[name].blank?
          next if assoc.klass.lookup(id: data[name])
          raise ArgumentError, "Invalid value for param '#{name}': #{data[name].inspect}"
        end
        clean_params[attribute] = data[attribute]
      end

      # we do want to set this via database
      filter_unused_params(clean_params)
    end

    private

=begin

remove all not used params of object (per default :updated_at, :created_at, :updated_by_id and :created_by_id)

if import mode is enabled, just do not used :action and :controller

  result = Model.filter_unused_params(params)

returns

  result = params # params without listed attributes

=end

    def filter_unused_params(data)
      params = %i[action controller updated_at created_at updated_by_id created_by_id updated_by created_by]
      if Setting.get('import_mode') == true
        params = %i[action controller]
      end
      params.each do |key|
        data.delete(key)
      end
      data
    end

  end

=begin

merge preferences param

  record = Model.find(123)

  new_preferences = record.param_preferences_merge(param_preferences)

=end

  def param_preferences_merge(new_params)
    return new_params if new_params.blank?
    return new_params if preferences.blank?
    new_params[:preferences] = preferences.merge(new_params[:preferences] || {})
    new_params
  end
end
