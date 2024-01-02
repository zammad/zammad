# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :notification_factory_renderer, class: 'NotificationFactory::Renderer' do
    objects { nil }
    locale   { 'en-en' }
    template { '' }
    escape   { true }
    url_encode { false }
    trusted { false }

    initialize_with { new(objects:, locale:, template:, escape:, url_encode:, trusted:) }
  end
end
