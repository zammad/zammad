# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :'ticket/article/type', aliases: %i[ticket_article_type] do
    sequence(:name) { |n| "#{n} type" }
    communication   { true }
    updated_by_id   { 1 }
    created_by_id   { 1 }
  end
end
