// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '#shared/i18n.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { flushPromises } from '@vue/test-utils'
import CommonBackButton from '../CommonBackButton.vue'

// $walker.back not tested because there is a unit test for it
describe('rendering common back button', () => {
  it('renders label', async () => {
    window.history.replaceState({ back: '/back' }, '/back')

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

    i18n.setTranslationMap(new Map([]))
  })

  it('renders home button, if no history is present', async () => {
    window.history.replaceState({}, '')

    const view = renderComponent(CommonBackButton, {
      router: true,
      props: {
        fallback: '/',
      },
    })

    expect(view.getByRole('button', { name: 'Go home' })).toBeInTheDocument()
    expect(view.getByIconName('mobile-home')).toBeInTheDocument()

    await view.rerender({
      label: 'Back',
    })

    expect(view.container).toHaveTextContent('Home')
  })

  it('renders home button, if history is present and previous route is home', async () => {
    window.history.replaceState({ back: '/' }, '/')

    const view = renderComponent(CommonBackButton, {
      router: true,
      props: {
        fallback: '/',
      },
    })

    expect(view.getByRole('button', { name: 'Go home' })).toBeInTheDocument()
    expect(view.getByIconName('mobile-home')).toBeInTheDocument()

    await view.rerender({
      label: 'Back',
    })

    expect(view.container).toHaveTextContent('Home')
  })

  it('renders back button, if history is present', async () => {
    window.history.replaceState(
      { back: '/tickets/1/information/customer' },
      '/tickets/1/information/customer',
    )

    const view = renderComponent(CommonBackButton, {
      router: true,
      props: {
        fallback: '/',
      },
    })

    expect(view.getByRole('button', { name: 'Go back' })).toBeInTheDocument()
    expect(view.getByIconName('mobile-chevron-left')).toBeInTheDocument()

    await view.rerender({
      label: 'Back',
    })

    expect(view.container).toHaveTextContent('Back')
  })
})
