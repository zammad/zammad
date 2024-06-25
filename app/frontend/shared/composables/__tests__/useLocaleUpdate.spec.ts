// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { beforeEach, describe, expect, vi } from 'vitest'

import { initializePiniaStore } from '#tests/support/components/renderComponent.ts'
import { waitUntil } from '#tests/support/utils.ts'

import { mockLocalesQuery } from '#shared/graphql/queries/locales.mocks.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import { useLocaleUpdate } from '../useLocaleUpdate.ts'

const mockUpdateLocaleMutationHandler = () => {
  const sendMock = vi.fn()
  MutationHandler.prototype.send = sendMock

  return {
    sendMock,
  }
}
const mockedLocales = [
  { locale: 'de', name: 'Deutsch' },
  { locale: 'en', name: 'English' },
]
describe('useLocaleUpdate', () => {
  beforeEach(() => {
    mockLocalesQuery({ locales: [{ locale: 'en', name: 'English' }] })
    initializePiniaStore()
    mockLocalesQuery({
      locales: mockedLocales,
    })
  })
  it('return translation link and label', () => {
    const { translation } = useLocaleUpdate()
    expect(translation.link).toBe('https://translations.zammad.org/')
  })
  it('isSavingLocale is initially false', () => {
    const { isSavingLocale } = useLocaleUpdate()
    expect(isSavingLocale.value).toBe(false)
  })
  it('returns correct modelCurrentLocale', () => {
    const { modelCurrentLocale } = useLocaleUpdate()
    // default locale is 'en'
    expect(modelCurrentLocale.value).toBe('en')
  })
  it('returns a list of locales', async () => {
    const { loadLocales } = useLocaleStore()
    await loadLocales()
    const { localeOptions } = useLocaleUpdate()
    const expectedOptions = [
      { value: 'de', label: 'Deutsch' },
      { value: 'en', label: 'English' },
    ]
    expect(localeOptions.value).toEqual(expectedOptions)
  })
  it('updates modelCurrentLocale correctly', async () => {
    const { sendMock } = mockUpdateLocaleMutationHandler()
    const { modelCurrentLocale, isSavingLocale } = useLocaleUpdate()
    modelCurrentLocale.value = 'de'
    expect(isSavingLocale.value).toBe(true)
    expect(sendMock).toHaveBeenCalledOnce()
    expect(sendMock).toHaveBeenCalledWith({
      locale: 'de',
    })
    await waitUntil(() => {
      return isSavingLocale.value === false
    })
    expect(modelCurrentLocale.value).toBe('de')
    expect(isSavingLocale.value).toBe(false)
  })
})
