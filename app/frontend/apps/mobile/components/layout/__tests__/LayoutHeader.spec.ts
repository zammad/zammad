// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@shared/i18n'
import { renderComponent } from '@tests/support/components'
import LayoutHeader from '../LayoutHeader.vue'

describe('mobile app header', () => {
  it("doesn't render, if not specified", () => {
    const view = renderComponent(LayoutHeader, { router: true })

    expect(view.queryByTestId('appHeader')).not.toBeInTheDocument()
  })

  it('renders title, if specified', async () => {
    const view = renderComponent(LayoutHeader, {
      props: { title: 'Test' },
      router: true,
    })

    expect(view.getByTestId('appHeader')).toBeInTheDocument()
    expect(view.getByText('Test')).toBeInTheDocument()

    i18n.setTranslationMap(new Map([['Test2', 'Translated']]))

    await view.rerender({ title: 'Test2' })

    expect(view.getByText('Translated')).toBeInTheDocument()
  })

  it('can add custom class to title', () => {
    const view = renderComponent(LayoutHeader, {
      props: {
        title: 'Test',
        titleClass: 'test-class',
      },
      router: true,
    })

    expect(view.getByText('Test')).toHaveClass('test-class')
  })

  it('renders back button, if specified', async () => {
    const view = renderComponent(LayoutHeader, {
      props: {
        backUrl: '/',
        backTitle: 'Back',
      },
      router: true,
    })

    const backButton = view.getByText('Back')

    expect(backButton).toBeInTheDocument()

    i18n.setTranslationMap(new Map([['Test2', 'Translated']]))

    await view.rerender({ backTitle: 'Test2', backUrl: '/' })

    expect(view.getByText('Translated')).toBeInTheDocument()
  })

  it('renders action, if specified', async () => {
    const onAction = vi.fn()

    const view = renderComponent(LayoutHeader, {
      props: {
        onAction,
        actionTitle: 'Action',
      },
      router: true,
    })

    const actionButton = view.getByText('Action')

    expect(actionButton).toBeInTheDocument()

    await view.events.click(actionButton)

    expect(onAction).toHaveBeenCalled()

    i18n.setTranslationMap(new Map([['Test2', 'Translated']]))

    await view.rerender({ actionTitle: 'Test2', onAction })

    expect(view.getByText('Translated')).toBeInTheDocument()
  })
})
