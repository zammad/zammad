class RenameGroupToIncoming < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    group = Group.find_by(id: 1)
    group.name = 'Incoming'
    group.save!
    
  end
end