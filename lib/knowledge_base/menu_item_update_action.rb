# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase
  class MenuItemUpdateAction
    def initialize(kb_locale, location, menu_items_data)
      @kb_locale       = kb_locale
      @location        = location
      @menu_items_data = menu_items_data
    end

    def scope
      @kb_locale.menu_items.location(@location)
    end

    def perform!
      raise_unprocessable if !all_ids_present?

      KnowledgeBase::MenuItem.transaction do
        KnowledgeBase::MenuItem.acts_as_list_no_update do
          remove_deleted
          update_order
        end
      end
    end

    # Mass-update KB menu items
    #
    # @param [KnowledgeBase] knowledge_base
    # @param [[<Hash>]] params @see .update_location_params!
    #
    # @return [<KnowledgeBase::MenuItem>]
    def self.update_using_params!(knowledge_base, params)
      return if params.blank?

      params
        .map { |location_params| update_location_using_params! knowledge_base, location_params }.sum(&:reload)
    end

    # Mass-update KB menu items in a given location
    #
    # @param [KnowledgeBase] knowledge_base
    # @param [Hash] location_params
    #
    # @option location_params [Integer] :kb_locale_id
    # @option location_params [String] :location header or footer
    # @option location_params [[<Hash>]] :menu_items @see #update_order
    def self.update_location_using_params!(knowledge_base, location_params)
      action = new(
        knowledge_base.kb_locales.find(location_params[:kb_locale_id]),
        location_params[:location],
        location_params[:menu_items]
      )

      action.perform!
      action.scope
    end

    private

    def update_order
      old_items = scope.to_a

      @menu_items_data
        .reject { |elem| elem[:_destroy] }
        .each_with_index do |data_elem, index|
          item = old_items.find { |record| record.id == data_elem[:id] } || scope.build

          item.position = index
          item.title    = data_elem[:title]
          item.url      = data_elem[:url]
          item.new_tab  = data_elem[:new_tab]

          item.save!
        end
    end

    def remove_deleted
      @menu_items_data
        .select { |elem| elem[:_destroy] }
        .pluck(:id)
        .tap { |array| @kb_locale.menu_items.where(id: array).destroy_all }
    end

    def all_ids_present?
      old_ids = scope.pluck(:id)
      new_ids = @menu_items_data.map { |elem| elem[:id]&.to_i }.compact

      old_ids.sort == new_ids.sort
    end

    def raise_unprocessable
      raise Exceptions::UnprocessableEntity, 'Provide position of all items in scope'
    end
  end
end
