class UpdateLogo < ActiveRecord::Migration
  def up

    return if !Setting.find_by(name: 'product_logo')
    StaticAssets.read
    StaticAssets.sync
  end
end
