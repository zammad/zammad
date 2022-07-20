// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { TranslationsDocument } from '@shared/graphql/queries/translations.api'
import type { LocalesQuery } from '@shared/graphql/types'
import { EnumTextDirection } from '@shared/graphql/types'
import useLocaleStore from '@shared/stores/locale'
import { visitView } from '@tests/support/components/visitView'
import { mockAccount } from '@tests/support/mock-account'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { waitUntil } from '@tests/support/utils'
import { AccountLocaleDocument } from '../graphql/mutations/locale.api'

const locales: Record<string, LocalesQuery['locales'][number]> = {
  de: {
    locale: 'de-de',
    name: 'Deutsch',
    dir: EnumTextDirection.Ltr,
    alias: 'de',
    active: true,
  },
  ar: {
    locale: 'ar',
    name: 'Arabic',
    dir: EnumTextDirection.Rtl,
    alias: null,
    active: true,
  },
}

describe('account page', () => {
  beforeEach(() => {
    mockAccount({
      lastname: 'Doe',
      firstname: 'John',
    })
    const locale = useLocaleStore()
    locale.localeData = { ...locales.de }
    locale.locales = [{ ...locales.de }, { ...locales.ar }]
  })

  it('can view my account page', async () => {
    const view = await visitView('/account')

    const mainContent = view.getByTestId('appMain')
    expect(mainContent, 'have avatar').toHaveTextContent('JD')
    expect(mainContent, 'have my name').toHaveTextContent('John Doe')
    expect(mainContent, 'have logout button').toHaveTextContent('Sign out')
    expect(mainContent, 'has language').toHaveTextContent('Deutsch')
  })

  it('can change language', async () => {
    const view = await visitView('/account')

    const mutationUpdate = mockGraphQLApi(AccountLocaleDocument).willResolve({
      accountLocale: { success: true, errors: null },
    })
    const translationsMock = mockGraphQLApi(TranslationsDocument).willResolve({
      translations: {
        isCacheStillValid: true,
        cacheKey: 'key',
        translations: [],
      },
    })

    await view.events.click(view.getByLabelText('Language'))
    await view.events.click(await view.findByText('Arabic'))

    await waitUntil(() => mutationUpdate.spies.resolve.mock.calls.length > 0)

    expect(mutationUpdate.spies.resolve).toHaveBeenCalledTimes(1)
    expect(translationsMock.spies.resolve).toHaveBeenCalledTimes(1)
    expect(
      mutationUpdate.spies.resolve,
      'updated locale on backend',
    ).toHaveBeenCalledWith({ locale: 'ar' })
    expect(
      translationsMock.spies.resolve,
      'updated translations',
    ).toHaveBeenCalledWith(expect.objectContaining({ locale: 'ar' }))

    await view.events.click(view.getByLabelText('Language'))
    await view.events.click(await view.findByText('Deutsch'))

    await waitUntil(() => mutationUpdate.spies.resolve.mock.calls.length > 1)

    expect(mutationUpdate.spies.resolve).toHaveBeenCalledTimes(2)
    expect(translationsMock.spies.resolve).toHaveBeenCalledTimes(2)
    expect(mutationUpdate.spies.resolve).toHaveBeenCalledWith({
      locale: 'de-de',
    })
    expect(translationsMock.spies.resolve).toHaveBeenCalledWith(
      expect.objectContaining({
        locale: 'de-de',
      }),
    )
  })
})
