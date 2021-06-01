# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :smime_certificate do
    created_at         { Time.zone.now }
    updated_at         { Time.zone.now }

    transient do
      fixture { nil }
    end

    public_key { File.read( Rails.root.join("spec/fixtures/smime/#{fixture}.crt") ) if fixture }

    trait :with_private do
      private_key { File.read( Rails.root.join("spec/fixtures/smime/#{fixture}.key") ) }
      private_key_secret { File.read( Rails.root.join("spec/fixtures/smime/#{fixture}.secret") ).strip! }
    end
  end
end
