# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class TagsController < ApplicationController
  before_filter :authentication_check

  # GET /api/v1/tags
  def index
    list = Tag.list()

    # return result
    render :json => {
      :tags => list,
    }
  end

  # GET /api/v1/tags
  def list
    list = Tag.tag_list(
      :object => params[:object],
      :o_id   => params[:o_id],
    )

    # return result
    render :json => {
      :tags => list,
    }
  end

  # POST /api/v1/tag/add
  def add
    success = Tag.tag_add(
      :object        => params[:object],
      :o_id          => params[:o_id],
      :item          => params[:item],
    );
    if success
      render :json => success, :status => :created
    else
      render :json => success.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /api/v1/tag/remove
  def remove
    success = Tag.tag_remove(
      :object        => params[:object],
      :o_id          => params[:o_id],
      :item          => params[:item],
    );
    if success
      render :json => success, :status => :created
    else
      render :json => success.errors, :status => :unprocessable_entity
    end
  end

end
