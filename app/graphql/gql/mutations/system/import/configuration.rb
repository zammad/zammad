# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class System::Import::Configuration < BaseMutation
    description 'Verify and apply third-party system import configuration'

    argument :configuration, Gql::Types::Input::SystemImportConfigurationInputType, description: 'Configuration to validate'

    field :success, Boolean, null: false, description: 'Is the configuration valid?'

    def self.authorize(...)
      true
    end

    def resolve(configuration:)
      klass_name = "Service::System::Import::Apply#{configuration.source.camelize}Configuration"
      klass = klass_name.constantize

      begin
        klass.new(**configuration.to_h.except(:source)).execute
      rescue "#{klass_name}::UnreachableError".constantize, "#{klass_name}::TLSError".constantize => e
        return { success: false }.merge(error_response({ message: e.message, field: 'url' }))
      rescue "#{klass_name}::InaccessibleError".constantize => e
        errors = []
        %i[secret username].each do |field|
          next if !configuration.key?(field)

          errors << { message: e.message, field: field.to_s }
        end

        return { success: false, errors: errors }
      end

      { success: true }
    end
  end
end
