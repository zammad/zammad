
class EmailTicketCcRemove < ActiveRecord::Migration
  def up
    ObjectManager::Attribute.remove(object: 'Ticket', name: 'cc', force: true)
  end
end
