# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :notification_factory_renderer, class: 'NotificationFactory::Renderer' do
    objects { nil }
    locale   { 'en-en' }
    template { '' }
    escape   { true }
    url_encode { false }
    trusted { false }
    ignore_missing_objects { false }

    initialize_with { new(objects:, locale:, template:, escape:, url_encode:, trusted:, ignore_missing_objects:) }
  end
end
