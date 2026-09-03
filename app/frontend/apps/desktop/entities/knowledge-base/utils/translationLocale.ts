// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// Whether a translation belongs to the locale that asked for it, or is the fallback served for one
//   that has none.
//
// Asked here rather than on the server: a translation belongs to one locale by definition, so the
//   only place the requested locale is known is the caller - the route it came from, or the key of
//   the taskbar tab that holds it.
export const isTranslationMissing = (
  translation: { kbLocale?: { systemLocale?: { locale?: string } } } | null | undefined,
  localeCode: string | undefined,
) => {
  // Nothing was asked for, so nothing can be missing.
  if (!localeCode) return false

  // Read defensively: a tab renders whatever its cache entry holds, and a throw here would take
  //   down the whole tab list rather than one label.
  const translationLocale = translation?.kbLocale?.systemLocale?.locale

  if (!translationLocale) return true

  return translationLocale.toLowerCase() !== localeCode.toLowerCase()
}
