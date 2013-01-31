class OverviewUpdate < ActiveRecord::Migration
  def up
    add_column :overviews, :link,                  :string,  :limit => 250,  :null => false
    add_column :overviews, :prio,                 :integer,                 :null => false
    Overview.all.each {|overview|
      overview.link = overview.meta[:url]
      overview.name = overview.meta[:name]
      overview.prio = overview.meta[:prio]
      overview.save
    }
    remove_column :overviews, :meta
  end

  def down
  end
end
