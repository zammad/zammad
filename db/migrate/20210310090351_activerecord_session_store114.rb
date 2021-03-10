class ActiverecordSessionStore114 < ActiveRecord::Migration[5.2]
  def change
    ActionDispatch::Session::ActiveRecordStore.session_class.find_each(&:secure!)
  end
end
