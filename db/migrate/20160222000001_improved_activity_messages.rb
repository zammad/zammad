class ImprovedActivityMessages < ActiveRecord::Migration
  def up
    ActivityStream.destroy_all
  end
end
