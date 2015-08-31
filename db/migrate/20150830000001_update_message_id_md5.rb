class UpdateMessageIdMd5 < ActiveRecord::Migration
  def up
    Ticket::Article.all.each {|article|
      next if !article.message_id
      next if article.message_id_md5
      message_id_md5 = Digest::MD5.hexdigest(article.message_id)
      article.update_columns({ message_id_md5: message_id_md5 })
    }
  end
end
