# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :translation do
    locale        { 'de-de' }
    source        { 'date' }
    target        { 'dd/mm/yyyy' }
    created_by_id { 1 }
    updated_by_id { 1 }
  end
end
