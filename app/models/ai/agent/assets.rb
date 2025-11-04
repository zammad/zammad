# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Agent
  module Assets
    extend ActiveSupport::Concern

    def assets(data = {})
      app_model = self.class.to_app_model

      data[app_model] ||= {}
      return data if data[app_model][id]

      data[app_model][id] = attributes_with_association_ids

      data[app_model][id]['references'] = EnsuresNoRelatedObjects::EnsuresNoRelatedObjects.new(self).references

      data[app_model][id]['references'].each do |model, references|
        references.each do |reference|
          model.constantize.find(reference['id']).assets(data)
        end
      end

      data
    end
  end
end
