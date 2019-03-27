FactoryBot.define do
  factory :notification_factory_renderer, class: NotificationFactory::Renderer do
    objects  {}
    locale   { 'en-en' }
    template { '' }
    escape   { true }

    initialize_with { new(objects: objects, locale: locale, template: template, escape: escape) }
  end
end
