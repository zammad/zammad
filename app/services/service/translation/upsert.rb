# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Translation::Upsert < Service::Base
  attr_reader :locale, :source, :target

  def initialize(locale:, source:, target:)
    super()

    @locale = locale
    @source = source
    @target = target
  end

  def execute
    translation = Translation.find_source(locale, source)

    if translation
      translation.update!(target: target)
      return translation
    end

    Translation.create!(locale: locale, source: source, target: target, is_synchronized_from_codebase: false)
  end
end
