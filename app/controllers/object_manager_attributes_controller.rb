# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ObjectManagerAttributesController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  # GET /object_manager_attributes_list
  def list
    render json: {
      objects: ObjectManager.list_frontend_objects,
    }
  end

  # GET /object_manager_attributes
  def index
    render json: ObjectManager::Attribute.list_full
  end

  # GET /object_manager_attributes/1
  def show
    model_show_render(ObjectManager::Attribute, params)
  end

  # POST /object_manager_attributes
  def create
    # check if attribute already exists
    exists = ObjectManager::Attribute.get(
      object: permitted_params[:object],
      name:   permitted_params[:name],
    )
    raise Exceptions::UnprocessableEntity, 'already exists' if exists

    add_attribute_using_params(permitted_params.merge(position: 1550), status: :created)
  end

  # PUT /object_manager_attributes/1
  def update
    # check if attribute already exists
    exists = ObjectManager::Attribute.get(
      object: permitted_params[:object],
      name:   permitted_params[:name],
    )

    raise Exceptions::UnprocessableEntity, 'does not exist' if !exists

    add_attribute_using_params(permitted_params, status: :ok)
  end

  # DELETE /object_manager_attributes/1
  def destroy
    object_manager_attribute = ObjectManager::Attribute.find(params[:id])
    ObjectManager::Attribute.remove(
      object_lookup_id: object_manager_attribute.object_lookup_id,
      name:             object_manager_attribute.name,
    )
    model_destroy_render_item
  rescue => e
    logger.error e
    raise Exceptions::UnprocessableEntity, e
  end

  # POST /object_manager_attributes_discard_changes
  def discard_changes
    ObjectManager::Attribute.discard_changes
    render json: {}, status: :ok
  end

  # POST /object_manager_attributes_execute_migrations
  def execute_migrations
    ObjectManager::Attribute.migration_execute
    render json: {}, status: :ok
  end

  private

  def permitted_params
    @permitted_params ||= begin
      permitted = params.permit!.to_h

      if permitted[:data_type].match?(%r{^(boolean)$}) && permitted[:data_option][:options]
        # rubocop:disable Lint/BooleanSymbol
        if permitted[:data_option][:options][:false]
          permitted[:data_option][:options][false] = permitted[:data_option][:options].delete(:false)
        end

        if permitted[:data_option][:options][:true]
          permitted[:data_option][:options][true] = permitted[:data_option][:options].delete(:true)
        end

        case permitted[:data_option][:default]
        when 'true'
          permitted[:data_option][:default] = true
        when 'false'
          permitted[:data_option][:default] = false
        end
        # rubocop:enable Lint/BooleanSymbol
      end

      if permitted[:data_option]

        if !permitted[:data_option].key?(:default)
          permitted[:data_option][:default] = if permitted[:data_type].match?(%r{^(input|select|tree_select)$})
                                                ''
                                              end
        end

        if permitted[:data_option][:null].nil?
          permitted[:data_option][:null] = true
        end

        if !permitted[:data_option][:options].is_a?(Hash) &&
           !permitted[:data_option][:options].is_a?(Array)
          permitted[:data_option][:options] = {}
        end

        if !permitted[:data_option][:relation].is_a?(String)
          permitted[:data_option][:relation] = ''
        end
      else
        permitted[:data_option] = {
          default:  '',
          options:  {},
          relation: '',
          null:     true
        }
      end

      permitted
    end
  end

  def add_attribute_using_params(given_params, status:)
    attributes = given_params.slice(:object, :name, :display, :data_type, :data_option, :active, :screens, :position)
    attributes[:editable] = true

    object_manager_attribute = ObjectManager::Attribute.add(attributes)

    render json: object_manager_attribute.attributes_with_association_ids, status: status
  rescue => e
    logger.error e
    raise Exceptions::UnprocessableEntity, e
  end
end
