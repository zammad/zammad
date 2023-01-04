// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@shared/i18n'
import { renderComponent } from '@tests/support/components'
import { flushPromises } from '@vue/test-utils'
import CommonBackButton from '../CommonBackButton.vue'

// $walker.back not tested because there is a unit test for it
describe('rendering common back button', () => {
  it('renders label', async () => {
    const view = renderComponent(CommonBackButton, {
      router: true,
      props: {
        fallback: '/back-url',
      },
    })

    expect(view.getByRole('button', { name: 'Go back' })).toBeInTheDocument()

    await view.rerender({
      label: 'Back',
    })

    expect(view.container).toHaveTextContent('Back')

    i18n.setTranslationMap(new Map([['Back', 'Zurück']]))

    await flushPromises()

    expect(view.container).toHaveTextContent('Zurück')

    expect(view.getByRole('button', { name: 'Go back' })).toBeInTheDocument()
  })
})
