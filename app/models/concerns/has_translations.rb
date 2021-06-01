# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasTranslations
  extend ActiveSupport::Concern

  included do
    has_many :translations, class_name: translation_class_name, # rubocop:disable Rails/ReflectionClassName
                            inverse_of: name.demodulize.underscore,
                            dependent:  :destroy

    validate :validate_translations

    accepts_nested_attributes_for :translations

    # returns objects with single translation according to given locale.
    # If no locale is given, defaults to Knowledge Base's primary locale
    scope :localed, lambda { |system_locale_or_id|
      output = eager_load(:translations).joins(translations: { kb_locale: :knowledge_base })

      if system_locale_or_id.present?
        output.where('knowledge_base_locales.system_locale_id' => system_locale_or_id)
      else
        output.where('knowledge_base_locales.system_locale_id' => -1)
      end
    }
  end

  def translation
    translations.first
  end

  def translation_to(kb_locale_or_id)
    translations.find_by(kb_locale_id: kb_locale_or_id)
  end

  def translation_preferred(kb_locale_or_id)
    translation_to(kb_locale_or_id) || translation_primary || translations.first
  end

  def translation_primary
    translations.joins(:kb_locale).find_by(knowledge_base_locales: { primary: true })
  end

  class_methods do
    def translation_class_name
      "#{name}::Translation"
    end

    def translation_class
      translation_class_name.constantize
    end
  end

  private

  def validate_translations
    translations
      .to_a
      .reject(&:valid?)
      .each do |elem|
        error_key = elem.errors.keys.first
        errors.add "translations.#{error_key}", elem.errors.messages[error_key].first
      end
  end
end
