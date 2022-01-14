# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :notification_factory_renderer, class: 'NotificationFactory::Renderer' do
    objects { nil }
    locale   { 'en-en' }
    template { '' }
    escape   { true }
    trusted  { false }

    initialize_with { new(objects: objects, locale: locale, template: template, escape: escape, trusted: trusted) }
  end
end
