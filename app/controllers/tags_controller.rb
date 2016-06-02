# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class TagsController < ApplicationController
  before_action :authentication_check

  # GET /api/v1/tag_search?term=abc
  def search
    list = Tag::Item.where('name_downcase LIKE ?', "#{params[:term].strip.downcase}%").order('name ASC').limit(params[:limit] || 10)
    results = []
    list.each {|item|
      result = {
        id: item.id,
        value: item.name,
      }
      results.push result
    }
    render json: results
  end

  # GET /api/v1/tags
  def list
    list = Tag.tag_list(
      object: params[:object],
      o_id: params[:o_id],
    )

    # return result
    render json: {
      tags: list,
    }
  end

  # POST /api/v1/tag/add
  def add
    success = Tag.tag_add(
      object: params[:object],
      o_id: params[:o_id],
      item: params[:item].strip,
    )
    if success
      render json: success, status: :created
    else
      render json: success.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/tag/remove
  def remove
    success = Tag.tag_remove(
      object: params[:object],
      o_id: params[:o_id],
      item: params[:item].strip,
    )
    if success
      render json: success, status: :created
    else
      render json: success.errors, status: :unprocessable_entity
    end
  end

  # GET /api/v1/tag_list
  def admin_list
    list = Tag::Item.order('name ASC').limit(params[:limit] || 1000)
    results = []
    list.each {|item|
      result = {
        id: item.id,
        name: item.name,
        count: Tag.where(tag_item_id: item.id).count
      }
      results.push result
    }
    render json: results
  end

  # POST /api/v1/tag_list
  def admin_create
    return if deny_if_not_role('Admin')
    name = params[:name].strip
    if !Tag.tag_item_lookup(name)
      Tag::Item.create(name: name)
    end
    render json: {}
  end

  # PUT /api/v1/tag_list/:id
  def admin_rename
    return if deny_if_not_role('Admin')
    name = params[:name].strip
    tag_item = Tag::Item.find(params[:id])
    existing_tag_id = Tag.tag_item_lookup(name)
    if existing_tag_id

      # assign to already existing tag
      Tag.where(tag_item_id: tag_item.id).update_all(tag_item_id: existing_tag_id)

      # delete not longer used tag
      tag_item.destroy

    # update new tag name
    else
      tag_item.name = name
      tag_item.save
    end
    render json: {}
  end

  # DELETE /api/v1/tag_list/:id
  def admin_delete
    return if deny_if_not_role('Admin')
    tag_item = Tag::Item.find(params[:id])
    Tag.where(tag_item_id: tag_item.id).destroy_all
    tag_item.destroy
    render json: {}
  end

end
