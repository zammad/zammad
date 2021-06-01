# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class FixedTwitterTicketArticlePreferences7 < ActiveRecord::Migration[5.0]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # find article preferences with Twitter::NullObject and replace it with nill to prevent elasticsearch index issue
    article_type_ids = Ticket::Article::Type.where(name: ['twitter status', 'twitter direct-message']).pluck(:id)
    article_ids = Ticket::Article.where(type_id: article_type_ids).pluck(:id)
    article_ids.each do |article_id|
      article = Ticket::Article.find(article_id)
      next if !article.preferences

      changed = false
      article.preferences.each_value do |value|
        next if value.class != ActiveSupport::HashWithIndifferentAccess

        value.each do |sub_key, sub_level|
          if sub_level.instance_of?(NilClass)
            value[sub_key] = nil
            next
          end
          if sub_level.instance_of?(Twitter::Place) || sub_level.instance_of?(Twitter::Geo)
            value[sub_key] = sub_level.to_h
            changed = true
            next
          end
          next if sub_level.class != Twitter::NullObject

          value[sub_key] = nil
          changed = true
        end
      end

      if article.preferences[:twitter]&.key?(:geo) && article.preferences[:twitter][:geo].nil?
        article.preferences[:twitter][:geo] = {}
        changed = true
      end

      if article.preferences[:twitter]&.key?(:place) && article.preferences[:twitter][:place].nil?
        article.preferences[:twitter][:place] = {}
        changed = true
      end

      next if !changed

      article.save!
    end

  end
end
