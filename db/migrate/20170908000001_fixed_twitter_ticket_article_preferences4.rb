class FixedTwitterTicketArticlePreferences4 < ActiveRecord::Migration
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    # find article preferences with Twitter::NullObject and replace it with nill to prevent elasticsearch index issue
    article_type_ids = Ticket::Article::Type.where(name: ['twitter status', 'twitter direct-message']).pluck(:id)
    article_ids = Ticket::Article.where(type_id: article_type_ids).pluck(:id)
    article_ids.each { |article_id|
      article = Ticket::Article.find(article_id)
      next if !article.preferences
      changed = false
      article.preferences.each { |_key, value|
        next if value.class != ActiveSupport::HashWithIndifferentAccess
        value.each { |sub_key, sub_level|
          if sub_level.class == NilClass
            value[sub_key] = nil
            next
          end
          if sub_level.class == Twitter::Place
            value[sub_key] = sub_level.attrs
            changed = true
            next
          end
          next if sub_level.class != Twitter::NullObject
          value[sub_key] = nil
          changed = true
        }
      }
      next if !changed
      article.save!
    }

  end
end
