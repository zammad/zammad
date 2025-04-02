# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ssl_certificate do
    transient do
      fixture { nil }
    end

    # Use existing fixture files from smime folder.
    certificate { Rails.root.join("spec/fixtures/files/smime/#{fixture}.crt").read if fixture }
  end
end
