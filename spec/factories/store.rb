# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :store do
    object { 'UploadCache' }
    o_id { 1 }
    preferences { {} }
    created_by_id { 1 }

    factory :store_image do
      data { Rails.root.join('test/data/image/1x1.png').binread }
      filename { '1x1.png' }
    end
  end
end
