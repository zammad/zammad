// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
    expect(alert).toHaveClass('alert-info')

    expect(view.getByIconName('desktop-info-circle')).toBeInTheDocument()
    expect(view.queryByIconName('mobile-close')).not.toBeInTheDocument()
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
    expect(alert).toHaveClass('alert-error')

    expect(view.getByIconName('desktop-x-circle')).toBeInTheDocument()
    expect(view.queryByIconName('mobile-close')).not.toBeInTheDocument()
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
    expect(alert).toHaveClass('alert-info')
    expect(view.getByIconName('mobile-close')).toBeInTheDocument()
  })

  it('renders an alert with a link', () => {
    const view = renderComponent(CommonAlert, {
      router: true,
      props: {
        link: 'https://zammad.com',
        linkText: 'Zammad',
      },
      slots: {
        default: 'Dummy',
      },
    })

    const alert = view.getByTestId('common-alert')

    expect(alert).toHaveTextContent('Dummy')
    expect(alert).toHaveClass('alert-info')

    const link = view.getByText('Zammad')
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', 'https://zammad.com')
  })
})
