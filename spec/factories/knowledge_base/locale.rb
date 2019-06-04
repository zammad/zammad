FactoryBot.define do
  factory 'knowledge_base/locale', aliases: %i[knowledge_base_locale] do
    knowledge_base { nil }
    system_locale  { Locale.first }

    before :create do |kb_locale|
      if kb_locale.knowledge_base.blank?
        create(:knowledge_base, given_kb_locale: kb_locale)
      end
    end
  end
end
