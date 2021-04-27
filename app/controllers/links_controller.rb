# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class LinksController < ApplicationController
  prepend_before_action :authentication_check

  # GET /api/v1/links
  def index
    links = Link.list(
      link_object:       params[:link_object],
      link_object_value: params[:link_object_value],
      user:              current_user,
    )

    linked_objects = links
                     .map { |elem| elem['link_object']&.safe_constantize&.lookup(id: elem['link_object_value']) }
                     .compact

    # return result
    render json: {
      links:  links,
      assets: ApplicationModel::CanAssets.reduce(linked_objects),
    }
  end

  # POST /api/v1/links/add
  def add
    object = case params[:link_object_source]
             when 'Ticket'
               Ticket.find_by(number: params[:link_object_source_number])
             when 'KnowledgeBase::Answer::Translation'
               KnowledgeBase::Answer::Translation.find_by(id: params[:link_object_source_number])
             end

    if !object
      render json: { error: 'No such object!' }, status: :unprocessable_entity
      return
    end

    link = Link.add(
      link_type:                params[:link_type],
      link_object_target:       params[:link_object_target],
      link_object_target_value: params[:link_object_target_value],
      link_object_source:       params[:link_object_source],
      link_object_source_value: object.id,
    )

    if link
      render json: link, status: :created
    else
      render json: link.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/links/remove
  def remove
    link = Link.remove(params)

    if link
      render json: link, status: :created
    else
      render json: link.errors, status: :unprocessable_entity
    end
  end

end
