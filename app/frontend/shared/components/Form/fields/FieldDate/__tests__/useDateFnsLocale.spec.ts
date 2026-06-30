// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'

import { initializePiniaStore } from '#tests/support/components/renderComponent.ts'
import { nullableMock } from '#tests/support/utils.ts'

import type { LocalesQuery } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import { useDateFnsLocale, importDateFnsLocale } from '../useDateFnsLocale.ts'

describe('importDateFnsLocale', () => {
  it('imports the correct locale based on the provided locale key', async () => {
    const localeKey = 'en-gb'
    const localeModule = await importDateFnsLocale(localeKey)

    expect(localeModule).toHaveProperty('enGB')
  })

  it('imports the fallback en-US locale if unknown locale key was passed', async () => {
    const localeKey = 'xx-xx'
    const localeModule = await importDateFnsLocale(localeKey)

    expect(localeModule).toHaveProperty('enUS')
  })
})

describe('useDateFnsLocale', () => {
  beforeEach(() => {
    initializePiniaStore()
  })

  it('returns the correct date-fns locale based on the current locale store value', async () => {
    const locale = useLocaleStore()

    locale.localeData = nullableMock<LocalesQuery['locales'][number]>({
      __typename: 'Locale',
      locale: 'en-gb',
    })

    const { dateFnsLocale } = useDateFnsLocale()

    await flushPromises()

    expect(dateFnsLocale.value).toHaveProperty('code', 'en-GB')
  })

  it('returns the fallback en-US locale if the current locale is unsupported', async () => {
    const locale = useLocaleStore()

    locale.localeData = nullableMock<LocalesQuery['locales'][number]>({
      __typename: 'Locale',
      locale: 'xx-xx',
    })

    const { dateFnsLocale } = useDateFnsLocale()

    await flushPromises()

    expect(dateFnsLocale.value).toHaveProperty('code', 'en-US')
  })
})
