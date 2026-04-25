// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computedAsync } from '@vueuse/core'

import { useLocaleStore } from '#shared/stores/locale.ts'

import type { Locale } from 'date-fns'
import type { Ref } from 'vue'

export const importDateFnsLocale = async (localeKey: string) => {
  switch (localeKey.toLowerCase()) {
    case 'ar':
      return await import('date-fns/locale/ar')
    case 'bg':
      return await import('date-fns/locale/bg')
    case 'ca':
      return await import('date-fns/locale/ca')
    case 'cs':
      return await import('date-fns/locale/cs')
    case 'da':
      return await import('date-fns/locale/da')
    case 'de-de':
      return await import('date-fns/locale/de')
    case 'el':
      return await import('date-fns/locale/el')
    case 'en-ca':
      return await import('date-fns/locale/en-CA')
    case 'en-gb':
      return await import('date-fns/locale/en-GB')
    case 'en-us':
      return await import('date-fns/locale/en-US')
    case 'es-ca':
      return await import('date-fns/locale/ca')
    case 'es-co':
      return await import('date-fns/locale/es')
    case 'es-es':
      return await import('date-fns/locale/es')
    case 'es-mx':
      return await import('date-fns/locale/es')
    case 'et':
      return await import('date-fns/locale/et')
    case 'fa-ir':
      return await import('date-fns/locale/fa-IR')
    case 'fi':
      return await import('date-fns/locale/fi')
    case 'fr-ca':
      return await import('date-fns/locale/fr-CA')
    case 'fr-fr':
      return await import('date-fns/locale/fr')
    case 'he-il':
      return await import('date-fns/locale/he')
    case 'hi-in':
      return await import('date-fns/locale/hi')
    case 'hr':
      return await import('date-fns/locale/hr')
    case 'hu':
      return await import('date-fns/locale/hu')
    case 'id':
      return await import('date-fns/locale/id')
    case 'is':
      return await import('date-fns/locale/is')
    case 'it-it':
      return await import('date-fns/locale/it')
    case 'ja':
      return await import('date-fns/locale/ja')
    case 'ko-kr':
      return await import('date-fns/locale/ko')
    case 'lt':
      return await import('date-fns/locale/lt')
    case 'lv':
      return await import('date-fns/locale/lv')
    case 'ms-my':
      return await import('date-fns/locale/ms')
    case 'nl-nl':
      return await import('date-fns/locale/nl')
    case 'no-no':
      return await import('date-fns/locale/nb')
    case 'pl':
      return await import('date-fns/locale/pl')
    case 'pt-br':
      return await import('date-fns/locale/pt-BR')
    case 'pt-pt':
      return await import('date-fns/locale/pt')
    case 'ro-ro':
      return await import('date-fns/locale/ro')
    case 'ru':
      return await import('date-fns/locale/ru')
    case 'sk':
      return await import('date-fns/locale/sk')
    case 'sl':
      return await import('date-fns/locale/sl')
    case 'sr-cyrl-rs':
      return await import('date-fns/locale/sr')
    case 'sr-latn-rs':
      return await import('date-fns/locale/sr-Latn')
    case 'sv-se':
      return await import('date-fns/locale/sv')
    case 'th':
      return await import('date-fns/locale/th')
    case 'tr':
      return await import('date-fns/locale/tr')
    case 'uk':
      return await import('date-fns/locale/uk')
    case 'vi':
      return await import('date-fns/locale/vi')
    case 'zh-cn':
      return await import('date-fns/locale/zh-CN')
    case 'zh-tw':
      return await import('date-fns/locale/zh-TW')
    case 'rw': // date-fns does not have a locale for Kinyarwanda, so we fall back to English (United States)
    default:
      return await import('date-fns/locale/en-US')
  }
}

export const useDateFnsLocale = () => {
  const localeStore = useLocaleStore()

  const dateFnsLocale = computedAsync(async () => {
    const localeKey = localeStore?.localeData?.locale

    if (localeKey) {
      const importedLocale = await importDateFnsLocale(localeKey)
      if ('default' in importedLocale) return importedLocale.default
    }

    return (await import('date-fns/locale/en-US')).enUS
  }) as Ref<Locale>

  return { dateFnsLocale }
}
