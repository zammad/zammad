# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class ObjectManagerAttributesController < ApplicationController
  prepend_before_action { authentication_check(permission: 'admin.object') }

  # GET /object_manager_attributes_list
  def list
    render json: {
      objects: ObjectManager.list_frontend_objects,
    }
  end

  # GET /object_manager_attributes
  def index
    render json: ObjectManager::Attribute.list_full
  end

  # GET /object_manager_attributes/1
  def show
    model_show_render(ObjectManager::Attribute, params)
  end

  # POST /object_manager_attributes
  def create
    check_params

    # check if attribute already exists
    exists = ObjectManager::Attribute.get(
      object: params[:object],
      name: params[:name],
    )
    raise Exceptions::UnprocessableEntity, 'already exists' if exists

    begin
      object_manager_attribute = ObjectManager::Attribute.add(
        object: params[:object],
        name: params[:name],
        display: params[:display],
        data_type: params[:data_type],
        data_option: params[:data_option],
        active: params[:active],
        screens: params[:screens],
        position: 1550,
        editable: true,
      )
      render json: object_manager_attribute.attributes_with_association_ids, status: :created
    rescue => e
      raise Exceptions::UnprocessableEntity, e
    end
  end

  # PUT /object_manager_attributes/1
  def update
    check_params
    begin
      object_manager_attribute = ObjectManager::Attribute.add(
        object: params[:object],
        name: params[:name],
        display: params[:display],
        data_type: params[:data_type],
        data_option: params[:data_option],
        active: params[:active],
        screens: params[:screens],
        position: 1550,
        editable: true,
      )
      render json: object_manager_attribute.attributes_with_association_ids, status: :ok
    rescue => e
      raise Exceptions::UnprocessableEntity, e
    end
  end

  # DELETE /object_manager_attributes/1
  def destroy
    object_manager_attribute = ObjectManager::Attribute.find(params[:id])
    ObjectManager::Attribute.remove(
      object_lookup_id: object_manager_attribute.object_lookup_id,
      name: object_manager_attribute.name,
    )
    model_destroy_render_item
  end

  # POST /object_manager_attributes_discard_changes
  def discard_changes
    ObjectManager::Attribute.discard_changes
    render json: {}, status: :ok
  end

  # POST /object_manager_attributes_execute_migrations
  def execute_migrations
    ObjectManager::Attribute.migration_execute
    render json: {}, status: :ok
  end

  private

  def check_params
    if params[:data_type] =~ /^(boolean)$/
      if params[:data_option][:options]
        if params[:data_option][:options][:false]
          params[:data_option][:options][false] = params[:data_option][:options][:false]
          params[:data_option][:options].delete(:false)
        end
        if params[:data_option][:options][:true]
          params[:data_option][:options][true] = params[:data_option][:options][:true]
          params[:data_option][:options].delete(:true)
        end
      end
    end
    if params[:data_option] && !params[:data_option].key?(:default)
      params[:data_option][:default] = if params[:data_type] =~ /^(input|select|tree_select)$/
                                         ''
                                       end
    end
    return if !params[:data_option][:null].nil?
    params[:data_option][:null] = true
  end
end
