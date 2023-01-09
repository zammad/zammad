# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Zammad::TranslationCatalog::Writer::VerifyLocaleEntries < Zammad::TranslationCatalog::Writer::Base

  optional true

  # Languages with a completeness over this threshold must have an entry in locales.yml.
  COMPLETENESS_THRESHOLD_PERCENT = 20

  def write(_extracted_strings)
    missing_locale_entries?
    missing_language_files?
  end

  private

  def languages
    @languages ||= Rails.root.join('i18n').glob('zammad.*.po').map { |file| file.basename.to_s.split('.')[-2] }
  end

  def missing_locale_entries?
    languages.each do |l|
      next if Locale.exists?(locale: l)

      strings = Translation.cached_strings_for_locale(l).values
      completeness = ((strings.count { |s| s.translation.present? } / strings.count) * 100).to_i

      next if completeness < COMPLETENESS_THRESHOLD_PERCENT

      warn "Warning: language '#{l}' is #{completeness} % translated, but has no locale yet."
    end
  end

  def missing_language_files?

    skippable_locales = %w[en-us sr-latn-rs]

    Locale.all.each do |l|
      next if languages.include? l.locale
      next if skippable_locales.include? l.locale

      warn "Warning: locale '#{l.locale}' has no corresponding translation file."
    end
  end
end
