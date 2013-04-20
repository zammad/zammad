class TagsController < ApplicationController
  before_filter :authentication_check

  # GET /api/tags
  def index
    list = Tag.list()

    # return result
    render :json => {
      :tags => list,
    }
  end

  # GET /api/tags
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

  # POST /api/tag/add
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

  # DELETE /api/tag/remove
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
