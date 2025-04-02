# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :store do
    object        { 'UploadCache' }
    o_id          { 1 }
    preferences   { {} }
    created_by_id { 1 }

    txt

    trait :txt do
      filename { 'test.txt' }
      data     { 'some content' }
    end

    trait :image do
      filename    { '1x1.png' }
      preferences { { 'Content-Type' => "image/#{File.extname(filename).delete_prefix('.')}" } }
      data        { Rails.root.join('test/data/image/1x1.png').binread }
    end

    trait :ics do
      filename    { 'basic.ics' }
      preferences { { 'Content-Type' => 'text/calendar' } }
      data        { Rails.root.join('spec/fixtures/files/calendar/basic.ics').binread }
    end
  end
end
