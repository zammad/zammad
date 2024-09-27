# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class TagsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  # GET /api/v1/tag_search?term=abc
  def search
    results = Tag::Item
      .filter_or_recommended(params[:term])
      .limit(params[:limit] || 10)
      .map do |elem|
        {
          id:    elem.id,
          value: elem.name,
        }
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
    raise Exceptions::Forbidden if !::Tag.tag_allowed?(name: params[:item], user_id: UserInfo.current_user_id)

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
      render json: success
    else
      render json: success.errors, status: :unprocessable_entity
    end
  end

  # GET /api/v1/tag_list
  def admin_list
    list = Tag::Item.reorder(name: :asc).limit(params[:limit] || 5000)
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
