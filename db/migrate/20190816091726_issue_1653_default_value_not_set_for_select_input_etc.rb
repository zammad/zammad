class Issue1653DefaultValueNotSetForSelectInputEtc < ActiveRecord::Migration[5.2]
  def change
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    ObjectManager::Attribute.all.each do |attribute|
      next if !attribute.data_type.match?(/^input|select|tree_select|richtext|textarea|checkbox$/)
      next if attribute.data_option[:default].blank?

      ObjectManager::Attribute.add(
        object:        ObjectLookup.by_id(attribute.object_lookup_id),
        name:          attribute.name,
        display:       attribute.display,
        data_type:     attribute.data_type,
        data_option:   attribute.data_option,
        active:        attribute.active,
        screens:       attribute.screens,
        position:      attribute.position,
        created_by_id: attribute.created_by_id,
        updated_by_id: attribute.updated_by_id,
        created_at:    attribute.created_at,
        updated_at:    attribute.updated_at,
        editable:      attribute.editable,
        to_migrate:    true,
      )
    end

    # ATTENTION: this may take a while
    ObjectManager::Attribute.migration_execute
  end
end
