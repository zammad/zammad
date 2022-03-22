# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :smime_certificate do
    created_at         { Time.zone.now }
    updated_at         { Time.zone.now }

    transient do
      fixture { nil }
    end

    public_key { File.read(Rails.root.join("spec/fixtures/files/smime/#{fixture}.crt")) if fixture }

    trait :with_private do
      private_key { File.read(Rails.root.join("spec/fixtures/files/smime/#{fixture}.key")) }
      private_key_secret { File.read(Rails.root.join("spec/fixtures/files/smime/#{fixture}.secret")).strip! }
    end
  end
end
