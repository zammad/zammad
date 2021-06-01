# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationController::RendersModels
  extend ActiveSupport::Concern

  private

  # model helper
  def model_create_render(object, params)

    clean_params = object.association_name_to_id_convert(params)
    clean_params = object.param_cleanup(clean_params, true)

    # create object
    generic_object = object.new(clean_params)

    # set relations
    generic_object.associations_from_param(params)

    # save object
    generic_object.save!

    if response_expand?
      render json: generic_object.attributes_with_association_names, status: :created
      return
    end

    if response_full?
      render json: generic_object.class.full(generic_object.id), status: :created
      return
    end

    model_create_render_item(generic_object)
  end

  def model_create_render_item(generic_object)
    render json: generic_object.attributes_with_association_ids, status: :created
  end

  def model_update_render(object, params)

    # find object
    generic_object = object.find(params[:id])

    clean_params = object.association_name_to_id_convert(params)
    clean_params = object.param_cleanup(clean_params, true)

    generic_object.with_lock do

      # set relations
      generic_object.associations_from_param(params)

      # set attributes
      generic_object.update!(clean_params)

    end

    if response_expand?
      render json: generic_object.attributes_with_association_names, status: :ok
      return
    end

    if response_full?
      render json: generic_object.class.full(generic_object.id), status: :ok
      return
    end

    model_update_render_item(generic_object)
  end

  def model_update_render_item(generic_object)
    render json: generic_object.attributes_with_association_ids, status: :ok
  end

  def model_destroy_render(object, params)
    generic_object = object.find(params[:id])
    generic_object.destroy!
    model_destroy_render_item()
  end

  def model_destroy_render_item ()
    render json: {}, status: :ok
  end

  def model_show_render(object, params)

    if response_expand?
      generic_object = object.find(params[:id])
      render json: generic_object.attributes_with_association_names, status: :ok
      return
    end

    if response_full?
      render json: object.full(params[:id]), status: :ok
      return
    end

    model_show_render_item(object.find(params[:id]))
  end

  def model_show_render_item(generic_object)
    render json: generic_object.attributes_with_association_ids, status: :ok
  end

  def model_index_render(object, params)
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 500).to_i
    offset = (page - 1) * per_page

    sql_helper = ::SqlHelper.new(object: object)
    sort_by    = sql_helper.get_sort_by(params, 'id')
    order_by   = sql_helper.get_order_by(params, 'ASC')
    order_sql  = sql_helper.get_order(sort_by, order_by)

    generic_objects = object.order(Arel.sql(order_sql)).offset(offset).limit(per_page)

    if response_expand?
      list = []
      generic_objects.each do |generic_object|
        list.push generic_object.attributes_with_association_names
      end
      render json: list, status: :ok
      return
    end

    if response_full?
      assets = {}
      item_ids = []
      generic_objects.each do |item|
        item_ids.push item.id
        assets = item.assets(assets)
      end
      render json: {
        record_ids:  item_ids,
        assets:      assets,
        total_count: object.count
      }, status: :ok
      return
    end

    generic_objects_with_associations = []
    generic_objects.each do |item|
      generic_objects_with_associations.push item.attributes_with_association_ids
    end
    model_index_render_result(generic_objects_with_associations)
  end

  def model_index_render_result(generic_objects)
    render json: generic_objects, status: :ok
  end

  def model_references_check(object, params)
    generic_object = object.find(params[:id])
    result = Models.references(object, generic_object.id)
    return false if result.blank?

    raise Exceptions::UnprocessableEntity, 'Can\'t delete, object has references.'
  rescue => e
    raise Exceptions::UnprocessableEntity, e
  end
end
