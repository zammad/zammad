# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  module ObjectManager
    class FrontendAttributes < BaseQuery

      description 'Fetch meta information about object manager attributes for usage in frontend.'

      argument :object, Gql::Types::Enum::ObjectManagerObjectsType, required: true, description: 'Object name to fetch meta information for'
      argument :filter_screen, String, required: false, description: 'Only return attributes that are available on a specific screen'

      type [Gql::Types::ObjectManager::FrontendAttributeType], null: false

      def resolve(object:, filter_screen: nil)
        object_manager_attributes(object, filter_screen)
      end

      private

      def object_manager_attributes(object, filter_screen)
        attributes = ::ObjectManager::Object.new(object).attributes(context.current_user, nil, data_only: false)

        result = []
        attributes.each do |attribute|
          oa = attribute.attribute

          if filter_screen.present? && !apply_screen_filter?(oa, filter_screen)
            next
          end

          result << {
            name:        oa[:name],
            display:     oa[:display],
            data_type:   oa[:data_type],
            data_option: oa[:data_option],
          }
        end

        result
      end

      def apply_screen_filter?(attribute, filter_screen)
        return false if filter_screen.blank?
        return false if attribute.screens.blank?

        relevant_for_screen?(attribute.screens, filter_screen)
      end

      def relevant_for_screen?(screens, filter_screen)
        return false if !screens.key?(filter_screen)

        current_screen = screens[filter_screen]
        return false if current_screen.empty?

        shown = current_screen['shown']
        return true if shown.nil? || shown == true

        false
      end
    end
  end
end
