// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonAlert from '../CommonAlert.vue'

describe('CommonAlert.vue', () => {
  it('renders when no props are passed', () => {
    const view = renderComponent(CommonAlert, {
      slots: {
        default: 'Dummy',
      },
    })

    const alert = view.getByTestId('common-alert')

    expect(alert).toHaveTextContent('Dummy')
    expect(alert).toHaveClass('common-alert-info')

    expect(view.getByIconName('info')).toBeInTheDocument()
    expect(view.queryByIconName('close')).not.toBeInTheDocument()
  })

  it('renders an alert with a specific variant', () => {
    const view = renderComponent(CommonAlert, {
      props: {
        variant: 'danger',
      },
      slots: {
        default: 'Dummy',
      },
    })

    const alert = view.getByTestId('common-alert')

    expect(alert).toHaveTextContent('Dummy')
    expect(alert).toHaveClass('common-alert-danger')

    expect(view.getByIconName('close-small')).toBeInTheDocument()
    expect(view.queryByIconName('close')).not.toBeInTheDocument()
  })

  it('renders an dismissible alert', () => {
    const view = renderComponent(CommonAlert, {
      props: {
        dismissible: true,
      },
      slots: {
        default: 'Dummy',
      },
    })

    const alert = view.getByTestId('common-alert')

    expect(alert).toHaveTextContent('Dummy')
    expect(alert).toHaveClass('common-alert-info')
    expect(view.getByIconName('close')).toBeInTheDocument()
  })

  it('dismisses a dismissible alert', async () => {
    const view = renderComponent(CommonAlert, {
      props: {
        dismissible: true,
      },
      slots: {
        default: 'Dummy',
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Dismiss alert' }))

    expect(view.queryByTestId('common-alert')).not.toBeInTheDocument()
    expect(view.emitted().dismiss).toHaveLength(1)
  })

  it('offers nothing to dismiss an alert with, unless it is dismissible', () => {
    const view = renderComponent(CommonAlert, {
      slots: {
        default: 'Dummy',
      },
    })

    expect(view.queryByRole('button')).not.toBeInTheDocument()
  })
})
