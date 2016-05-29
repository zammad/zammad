# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class ObjectManagerAttributesController < ApplicationController
  before_action :authentication_check

  # GET /object_manager_attributes_list
  def list
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    render json: {
      objects: ObjectManager.list_frontend_objects,
    }
  end

  # GET /object_manager_attributes
  def index
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    render json: ObjectManager::Attribute.list_full
  end

  # GET /object_manager_attributes/1
  def show
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_show_render(ObjectManager::Attribute, params)
  end

  # POST /object_manager_attributes
  def create
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    check_params

    # check if attribute already exists
    exists = ObjectManager::Attribute.get(
      object: params[:object],
      name: params[:name],
    )
    if exists
      render json: model_match_error('already exists'), status: :unprocessable_entity
      return
    end

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
      render json: object_manager_attribute.attributes_with_associations, status: :created
    rescue => e
      logger.error e.message
      logger.error e.backtrace.inspect
      render json: model_match_error(e.message), status: :unprocessable_entity
    end
  end

  # PUT /object_manager_attributes/1
  def update
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
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
      render json: object_manager_attribute.attributes_with_associations, status: :ok
    rescue => e
      logger.error e.message
      logger.error e.backtrace.inspect
      render json: model_match_error(e.message), status: :unprocessable_entity
    end
  end

  # DELETE /object_manager_attributes/1
  def destroy
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    object_manager_attribute = ObjectManager::Attribute.find(params[:id])
    ObjectManager::Attribute.remove(
      object_lookup_id: object_manager_attribute.object_lookup_id,
      name: object_manager_attribute.name,
    )
    model_destory_render_item
  end

  # POST /object_manager_attributes_discard_changes
  def discard_changes
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    ObjectManager::Attribute.discard_changes
    render json: {}, status: :ok
  end

  # POST /object_manager_attributes_execute_migrations
  def execute_migrations
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
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
      params[:data_option][:default] = if params[:data_type] =~ /^(input|select)$/
                                         ''
                                       end
    end
    return if !params[:data_option][:null].nil?
    params[:data_option][:null] = true
  end
end
