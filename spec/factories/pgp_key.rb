# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :pgp_key, aliases: [:'pgp_key/zammad@localhost'] do
    updated_at    { Time.zone.now }
    updated_by_id { user.id }
    created_by_id { user.id }

    transient do
      fixture { 'zammad@localhost' }
      user    { association :admin }
    end

    key { Rails.root.join("spec/fixtures/files/pgp/#{fixture}.pub.asc").read }

    trait :with_private do
      key        { Rails.root.join("spec/fixtures/files/pgp/#{fixture}.asc").read }
      passphrase { Rails.root.join("spec/fixtures/files/pgp/#{fixture}.passphrase").read }
    end

    factory :'pgp_key/pgp1@example.com' do
      transient do
        fixture { 'pgp1@example.com' }
      end
    end

    factory :'pgp_key/pgp2@example.com' do
      transient do
        fixture { 'pgp2@example.com' }
      end
    end

    factory :'pgp_key/pgp3@example.com' do
      transient do
        fixture { 'pgp3@example.com' }
      end
    end

    factory :'pgp_key/multipgp2@example.com' do
      transient do
        fixture { 'multipgp2@example.com' }
      end
    end

    factory :'pgp_key/noexpirepgp1@example.com' do
      transient do
        fixture { 'noexpirepgp1@example.com' }
      end
    end

    factory :'pgp_key/pgp+smime-sender@example.com' do
      transient do
        fixture { 'pgp+smime-sender@example.com' }
      end
    end

    factory :'pgp_key/pgp+smime-recipient@example.com' do
      transient do
        fixture { 'pgp+smime-recipient@example.com' }
      end
    end
  end
end
