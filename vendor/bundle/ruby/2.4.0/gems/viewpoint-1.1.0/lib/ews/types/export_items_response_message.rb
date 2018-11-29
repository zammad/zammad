module Viewpoint::EWS::Types
  
  class ExportItemsResponseMessage
    include Viewpoint::EWS
    include Viewpoint::EWS::Types
    include Viewpoint::EWS::Types::Item

    BULK_KEY_PATHS = {
      :id          => [:item_id, :attribs, :id],
      :change_key  => [:item_id, :attribs, :change_key],
      :data        => [:data, :text]
    }

    BULK_KEY_TYPES = { }

    BULK_KEY_ALIAS = { }

    def initialize(ews, bulk_item)
      super(ews, bulk_item)
      @item = bulk_item
      @ews = ews
    end

    def id
      @item[:item_id][:attribs][:id]
    end

    def change_key
      @item[:item_id][:attribs][:change_key]
    end

    def data
      @item[:data][:text]
    end


    private

    def key_paths
      @key_paths ||= BULK_KEY_PATHS
    end

    def key_types
      @key_types ||= BULK_KEY_TYPES
    end

    def key_alias
      @key_alias ||= BULK_KEY_ALIAS
    end

  end
end