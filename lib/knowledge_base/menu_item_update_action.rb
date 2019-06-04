class KnowledgeBase
  class MenuItemUpdateAction
    def initialize(kb_locale, menu_items_data)
      @kb_locale       = kb_locale
      @menu_items_data = menu_items_data
    end

    def perform!
      raise_unprocessable unless all_ids_present?

      KnowledgeBase::MenuItem.transaction do
        KnowledgeBase::MenuItem.acts_as_list_no_update do
          remove_deleted
          update_order
        end
      end
    end

    private

    def update_order
      old_items = @kb_locale.menu_items.to_a

      @menu_items_data
        .reject { |elem| elem[:_destroy] }
        .each_with_index do |data_elem, index|
          item = old_items.find { |record| record.id == data_elem[:id] } || @kb_locale.menu_items.build

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
        .map    { |elem| elem[:id] }
        .tap    { |array| @kb_locale.menu_items.where(id: array).destroy_all }
    end

    def all_ids_present?
      old_ids = @kb_locale.menu_items.pluck(:id)
      new_ids = @menu_items_data.map { |elem| elem[:id]&.to_i }.compact

      old_ids.sort == new_ids.sort
    end

    def raise_unprocessable
      raise Exceptions::UnprocessableEntity, 'Provide position of all items in scope'
    end
  end
end
