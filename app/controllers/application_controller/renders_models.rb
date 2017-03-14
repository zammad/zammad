module ApplicationController::RendersModels
  extend ActiveSupport::Concern

  private

  # model helper
  def model_create_render(object, params)

    clean_params = object.association_name_to_id_convert(params)
    clean_params = object.param_cleanup(clean_params, true)

    # create object
    generic_object = object.new(clean_params)

    # save object
    generic_object.save!

    # set relations
    generic_object.associations_from_param(params)

    if params[:expand]
      render json: generic_object.attributes_with_association_names, status: :created
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

      # set attributes
      generic_object.update_attributes!(clean_params)

      # set relations
      generic_object.associations_from_param(params)
    end

    if params[:expand]
      render json: generic_object.attributes_with_association_names, status: :ok
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

    if params[:expand]
      generic_object = object.find(params[:id])
      render json: generic_object.attributes_with_association_names, status: :ok
      return
    end

    if params[:full]
      generic_object_full = object.full(params[:id])
      render json: generic_object_full, status: :ok
      return
    end

    generic_object = object.find(params[:id])
    model_show_render_item(generic_object)
  end

  def model_show_render_item(generic_object)
    render json: generic_object.attributes_with_association_ids, status: :ok
  end

  def model_index_render(object, params)
    offset = 0
    per_page = 500
    if params[:page] && params[:per_page]
      offset = (params[:page].to_i - 1) * params[:per_page].to_i
      limit = params[:per_page].to_i
    end

    if per_page > 500
      per_page = 500
    end

    generic_objects = if offset.positive?
                        object.limit(params[:per_page]).order(id: 'ASC').offset(offset).limit(limit)
                      else
                        object.all.order(id: 'ASC').offset(offset).limit(limit)
                      end

    if params[:expand]
      list = []
      generic_objects.each { |generic_object|
        list.push generic_object.attributes_with_association_names
      }
      render json: list, status: :ok
      return
    end

    if params[:full]
      assets = {}
      item_ids = []
      generic_objects.each { |item|
        item_ids.push item.id
        assets = item.assets(assets)
      }
      render json: {
        record_ids: item_ids,
        assets: assets,
      }, status: :ok
      return
    end

    generic_objects_with_associations = []
    generic_objects.each { |item|
      generic_objects_with_associations.push item.attributes_with_association_ids
    }
    model_index_render_result(generic_objects_with_associations)
  end

  def model_index_render_result(generic_objects)
    render json: generic_objects, status: :ok
  end

  def model_references_check(object, params)
    generic_object = object.find(params[:id])
    result = Models.references(object, generic_object.id)
    return false if result.empty?
    raise Exceptions::UnprocessableEntity, 'Can\'t delete, object has references.'
  rescue => e
    raise Exceptions::UnprocessableEntity, e
  end
end
