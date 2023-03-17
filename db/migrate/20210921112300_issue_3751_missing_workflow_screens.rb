# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3751MissingWorkflowScreens < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    fix_organization_screens_create
    fix_user_screens_create
  end

  def fix_organization_screens_create
    %w[name shared domain_assignment active].each do |name|
      field = ObjectManager::Attribute.find_by(name: name, object_lookup: ObjectLookup.find_by(name: 'Organization'))
      next if field.blank?

      field.screens['create'] ||= {}
      field.screens['create']['-all-'] ||= {}
      field.screens['create']['-all-']['null'] = false
      field.save
    end
  end

  def fix_user_screens_create
    %w[firstname lastname active].each do |name|
      field = ObjectManager::Attribute.find_by(name: name, object_lookup: ObjectLookup.find_by(name: 'User'))
      next if field.blank?

      field.screens['create'] ||= {}
      field.screens['create']['-all-'] ||= {}
      field.screens['create']['-all-']['null'] = false
      field.save
    end
  end
end
