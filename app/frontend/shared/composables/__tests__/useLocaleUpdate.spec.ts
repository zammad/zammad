// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
  { locale: 'de-de', name: 'Deutsch' },
  { locale: 'en-us', name: 'English (United States)' },
]
describe('useLocaleUpdate', () => {
  beforeEach(() => {
    mockLocalesQuery({ locales: [{ locale: 'en-us', name: 'English (United States)' }] })
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
    // default locale is 'en-us'
    expect(modelCurrentLocale.value).toBe('en-us')
  })
  it('returns a list of locales', async () => {
    const { loadLocales } = useLocaleStore()
    await loadLocales()
    const { localeOptions } = useLocaleUpdate()
    const expectedOptions = [
      { value: 'de-de', label: 'Deutsch' },
      { value: 'en-us', label: 'English (United States)' },
    ]
    expect(localeOptions.value).toEqual(expectedOptions)
  })
  it('updates modelCurrentLocale correctly', async () => {
    const { sendMock } = mockUpdateLocaleMutationHandler()
    const { modelCurrentLocale, isSavingLocale } = useLocaleUpdate()
    modelCurrentLocale.value = 'de-de'
    expect(isSavingLocale.value).toBe(true)
    expect(sendMock).toHaveBeenCalledOnce()
    expect(sendMock).toHaveBeenCalledWith({
      locale: 'de-de',
    })
    await waitUntil(() => {
      return isSavingLocale.value === false
    })
    expect(modelCurrentLocale.value).toBe('de-de')
    expect(isSavingLocale.value).toBe(false)
  })
})
