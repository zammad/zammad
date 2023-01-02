# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory 'knowledge_base/permission', aliases: %i[knowledge_base_permission] do
    permissionable { create(:knowledge_base_category) }
    role           { create(:role, permission_names: 'knowledge_base.editor') }
    access         { 'editor' }
  end
end
