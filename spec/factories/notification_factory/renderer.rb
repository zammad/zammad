# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :notification_factory_renderer, class: 'NotificationFactory::Renderer' do
    objects  { nil }
    locale   { 'en-en' }
    template { '' }
    escape   { true }

    initialize_with { new(objects: objects, locale: locale, template: template, escape: escape) }
  end
end
