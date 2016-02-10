class MigrateTextModules < ActiveRecord::Migration
  def up
    TextModule.all.each {|text_module|
      text_module.content = text_module.content.text2html
      text_module.save
    }
    Signature.all.each {|signature|
      signature.body = signature.body.text2html
      signature.save
    }
  end
end
