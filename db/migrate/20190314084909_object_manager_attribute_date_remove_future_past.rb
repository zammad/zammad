class ObjectManagerAttributeDateRemoveFuturePast < ActiveRecord::Migration[5.1]
  def change

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    ObjectManager::Attribute.where(data_type: 'date').each do |attribute|
      attribute.data_option = attribute.data_option.except(:future, :past)
      attribute.save!
    end
  end
end
