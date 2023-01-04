# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'ticket/article/type', aliases: %i[ticket_article_type] do
    sequence(:name) { |n| "#{n} type" }
    communication   { true }
    updated_by_id   { 1 }
    created_by_id   { 1 }
  end
end
