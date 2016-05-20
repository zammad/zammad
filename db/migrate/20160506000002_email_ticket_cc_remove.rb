
class EmailTicketCcRemove < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')
    object_lookup_id = ObjectLookup.by_name('Ticket')
    record = ObjectManager::Attribute.find_by(
      object_lookup_id: object_lookup_id,
      name: 'cc',
    )
    record.destroy if record
  end
end
