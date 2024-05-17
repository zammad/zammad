// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'

import { waitForUserCurrentLocaleMutationCalls } from '#shared/entities/user/current/graphql/mutations/userCurrentLocale.mocks.ts'
import { mockLocalesQuery } from '#shared/graphql/queries/locales.mocks.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'

describe('locale page', () => {
  it('can change language', async () => {
    mockLocalesQuery({
      locales: [
        {
          locale: 'de-de',
          name: 'Deutsch',
          dir: EnumTextDirection.Ltr,
          alias: 'de',
          active: true,
        },
        {
          locale: 'ar',
          name: 'Arabic',
          dir: EnumTextDirection.Rtl,
          alias: null,
          active: true,
        },
      ],
    })

    const view = await visitView('/personal-setting/locale')
    const localeField = view.getByLabelText('Your language')

    await view.events.click(localeField)

    const arabicLocale = view.getByText('Arabic')

    await view.events.click(arabicLocale)

    const calls = await waitForUserCurrentLocaleMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({ locale: 'ar' })

    expect(localeField).not.toHaveTextContent('Your language')
  })

  it('has link to zammad translations', async () => {
    const view = await visitView('/personal-setting/locale')

    expect(
      view.queryByText('You can help translating Zammad.'),
    ).toBeInTheDocument()
  })
})
