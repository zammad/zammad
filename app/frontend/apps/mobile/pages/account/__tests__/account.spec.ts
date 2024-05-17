// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { setupView } from '#tests/support/mock-user.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitUntil, waitUntilApisResolved } from '#tests/support/utils.ts'

import { UserCurrentLocaleDocument } from '#shared/entities/user/current/graphql/mutations/userCurrentLocale.api.ts'
import { ProductAboutDocument } from '#shared/graphql/queries/about.api.ts'
import { TranslationsDocument } from '#shared/graphql/queries/translations.api.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import type { LocalesQuery } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

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
    mockUserCurrent({
      lastname: 'Doe',
      firstname: 'John',
    })
    const locale = useLocaleStore()
    locale.localeData = { ...locales.de }
    locale.locales = [{ ...locales.de }, { ...locales.ar }]
  })

  it('can view my account page', async () => {
    mockPermissions([
      'user_preferences.avatar',
      'user_preferences.language',
      'admin',
    ])

    const languageApi = mockGraphQLApi(ProductAboutDocument).willResolve({
      productAbout: 'v1.0.0',
    })

    const view = await visitView('/account')

    await waitUntilApisResolved(languageApi)

    const mainContent = view.getByTestId('appMain')
    expect(mainContent, 'have avatar').toHaveTextContent('JD')
    expect(mainContent, 'have my name').toHaveTextContent('John Doe')
    expect(mainContent, 'have logout button').toHaveTextContent('Sign out')
    expect(mainContent, 'has language').toHaveTextContent('Deutsch')

    expect(languageApi.spies.resolve).toHaveBeenCalled()
    expect(mainContent, 'has version').toHaveTextContent('v1.0.0')
  })

  it('can change language', async () => {
    mockPermissions(['user_preferences.language'])

    const view = await visitView('/account')

    const mutationUpdate = mockGraphQLApi(
      UserCurrentLocaleDocument,
    ).willResolve({
      userCurrentLocale: { success: true, errors: null },
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

  it("can't see content without permissions", async () => {
    mockPermissions([])

    const languageApi = mockGraphQLApi(ProductAboutDocument).willResolve({
      productAbout: 'v1.0.0',
    })

    const view = await visitView('/account')

    expect(languageApi.spies.resolve).not.toHaveBeenCalled()

    const mainContent = view.getByTestId('appMain')
    expect(mainContent).not.toHaveTextContent('Language')
    expect(mainContent).not.toHaveTextContent('Version')
    expect(mainContent).not.toHaveTextContent('Avatar')
  })
})

test('correctly redirects from hash-based routes', async () => {
  setupView('agent')
  await visitView('/#profile')
  const router = getTestRouter()
  const route = router.currentRoute.value
  expect(route.name).toBe('AccountOverview')
})

test('correctly redirects from hash-based routes', async () => {
  setupView('agent')
  await visitView('/#profile/avatar')
  const router = getTestRouter()
  const route = router.currentRoute.value
  expect(route.name).toBe('PersonalSettingAvatar')
})
