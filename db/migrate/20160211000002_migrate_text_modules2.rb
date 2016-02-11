class MigrateTextModules2 < ActiveRecord::Migration
  def up
    TextModule.all.each {|text_module|
      text_module.content.gsub!('&lt;%=', '#{')
      text_module.content.gsub!('%&gt;', '}')
      text_module.save
    }
  end
end
