# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Concerns::EnsuresChecklistFeatureActive
  extend ActiveSupport::Concern

  included do

    def self.ensure_checklist_feature_active!
      raise Exceptions::Forbidden, 'The checklist feature is not active' if !Setting.get('checklist') # rubocop:disable Zammad/DetectTranslatableString
    end

  end
end
