# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :smime_certificate do
    created_at         { Time.zone.now }
    updated_at         { Time.zone.now }

    transient do
      fixture { nil }
    end

    public_key { Rails.root.join("spec/fixtures/files/smime/#{fixture}.crt").read if fixture }

    trait :with_private do
      private_key { Rails.root.join("spec/fixtures/files/smime/#{fixture}.key").read }
      private_key_secret { Rails.root.join("spec/fixtures/files/smime/#{fixture}.secret").read.strip! }
    end
  end
end
