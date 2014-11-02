# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class ObjectManagerAttributesController < ApplicationController
  before_filter :authentication_check


  # GET /object_manager_attributes_list
  def list
    return if deny_if_not_role('Admin')
    render :json => {
      :objects => ObjectManager.listObjects,
    }
    #model_index_render(ObjectManager::Attribute, params)
  end

  # GET /object_manager_attributes
  def index
    return if deny_if_not_role('Admin')
    render :json => ObjectManager::Attribute.list_full
    #model_index_render(ObjectManager::Attribute, params)
  end

  # GET /object_manager_attributes/1
  def show
    return if deny_if_not_role('Admin')
    model_show_render(ObjectManager::Attribute, params)
  end

  # POST /object_manager_attributes
  def create
    return if deny_if_not_role('Admin')
    model_create_render(ObjectManager::Attribute, params)
  end

  # PUT /object_manager_attributes/1
  def update
    return if deny_if_not_role('Admin')
    model_update_render(ObjectManager::Attribute, params)
  end

  # DELETE /object_manager_attributes/1
  def destroy
    return if deny_if_not_role('Admin')
    model_destory_render(ObjectManager::Attribute, params)
  end
end
