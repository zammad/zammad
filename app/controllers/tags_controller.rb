# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TagsController < ApplicationController
  prepend_before_action -> { authorize! }, only: %i[admin_list admin_create admin_rename admin_delete]
  prepend_before_action { authentication_check }

  # GET /api/v1/tag_search?term=abc
  def search
    list = Tag::Item.where('name_downcase LIKE ?', "%#{params[:term].strip.downcase}%").order(name: :asc).limit(params[:limit] || 10)
    results = []
    list.each do |item|
      result = {
        id:    item.id,
        value: item.name,
      }
      results.push result
    end
    render json: results
  end

  # GET /api/v1/tags
  def list
    list = Tag.tag_list(
      object: params[:object],
      o_id:   params[:o_id],
    )

    # return result
    render json: {
      tags: list,
    }
  end

  # POST /api/v1/tags/add
  def add
    success = Tag.tag_add(
      object: params[:object],
      o_id:   params[:o_id],
      item:   params[:item],
    )
    if success
      render json: success, status: :created
    else
      render json: success.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/tags/remove
  def remove
    success = Tag.tag_remove(
      object: params[:object],
      o_id:   params[:o_id],
      item:   params[:item],
    )
    if success
      render json: success, status: :created
    else
      render json: success.errors, status: :unprocessable_entity
    end
  end

  # GET /api/v1/tag_list
  def admin_list
    list = Tag::Item.order(name: :asc).limit(params[:limit] || 1000)
    results = []
    list.each do |item|
      result = {
        id:    item.id,
        name:  item.name,
        count: Tag.where(tag_item_id: item.id).count
      }
      results.push result
    end
    render json: results
  end

  # POST /api/v1/tag_list
  def admin_create
    Tag::Item.lookup_by_name_and_create(params[:name])
    render json: {}
  end

  # PUT /api/v1/tag_list/:id
  def admin_rename
    Tag::Item.rename(
      id:   params[:id],
      name: params[:name],
    )
    render json: {}
  end

  # DELETE /api/v1/tag_list/:id
  def admin_delete
    Tag::Item.remove(params[:id])
    render json: {}
  end

end
