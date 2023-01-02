# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  module ObjectManager
    class FrontendAttributes < BaseQueryWithPayload

      description 'Fetch meta information about object manager attributes for usage in frontend.'

      argument :object, Gql::Types::Enum::ObjectManagerObjectsType, description: 'Object name to fetch meta information for'

      field :attributes, [Gql::Types::ObjectManager::FrontendAttributeType, { null: false }], null: false, description: 'Attributes to be shown in the frontend'
      field :screens, [Gql::Types::ObjectManager::ScreenAttributesType, { null: false }], null: false, description: 'Screens with attributes to be shown in the frontend'

      def resolve(object:)
        object_manager_attributes(object)
      end

      private

      def object_manager_attributes(object)
        object_attributes = ::ObjectManager::Object.new(object).attributes(context.current_user, nil, data_only: false)

        frontend_attributes = []
        frontend_screens = {}

        object_attributes.each do |element|
          next if !check_attribute_frontend_screens(frontend_screens, element.screens, element.attribute.name)

          frontend_attributes << frontend_attribute_fields(element)
        end

        {
          attributes: frontend_attributes,
          screens:    frontend_screens.map { |screen, attributes| { name: screen, attributes: attributes } }
        }
      end

      def frontend_attribute_fields(element)
        attribute = element.attribute

        add_belongs_to_for_relation_attributes(attribute)

        {
          name:        attribute[:name],
          display:     attribute[:display],
          data_type:   attribute[:data_type],
          data_option: attribute[:data_option],
          screens:     element.screens,
          is_internal: !attribute[:editable],
        }
      end

      def add_belongs_to_for_relation_attributes(attribute)
        return if attribute[:data_option][:relation].blank? || attribute[:data_option][:belongs_to].present?

        attribute[:data_option][:belongs_to] = attribute[:name].humanize(capitalize: false)
      end

      def check_attribute_frontend_screens(frontend_screens, screens, name)
        attribute_shown = false

        screens.each do |screen, screen_data|
          frontend_screens[screen] ||= []

          next if !apply_screen_filter?(screen, screen_data)

          frontend_screens[screen] << name

          attribute_shown = true
        end

        attribute_shown
      end

      def apply_screen_filter?(screen, screen_data)
        return false if screen_data.empty?

        shown = screen_data['shown']
        return true if shown.nil? || shown == true || core_workflow_screen?(screen)

        false
      end

      def core_workflow_screen?(screen)
        core_workflow? && object_class.core_workflow_screens.include?(screen)
      end

      def core_workflow?
        @core_workflow ||= object_class.included_modules.include?(ChecksCoreWorkflow)
      end

      def object_class
        @object_class = "::#{context[:current_arguments][:object]}".constantize
      end
    end
  end
end
