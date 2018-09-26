FactoryBot.define do
  factory :notification_factory_renderer, class: NotificationFactory::Renderer do
    objects {}
    locale 'en-en'
    template ''
    escape true

    initialize_with { new(objects, locale, template, escape) }
  end
end
