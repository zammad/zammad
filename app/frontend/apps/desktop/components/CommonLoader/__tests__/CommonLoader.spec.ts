// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'

import CommonLoader from '../CommonLoader.vue'

describe('CommonLoader.vue', () => {
  it('does not render with default prop values', async () => {
    const view = renderComponent(CommonLoader)

    expect(view.queryByRole('status')).not.toBeInTheDocument()
  })

  it('renders loading animation with loading prop set', async () => {
    const view = renderComponent(CommonLoader, {
      props: {
        loading: true,
      },
    })

    const loader = view.getByRole('status')

    expect(getByIconName(loader, 'spinner')).toBeInTheDocument()
  })

  it('hides loading animation when loading prop is unset', async () => {
    const view = renderComponent(CommonLoader, {
      props: {
        loading: true,
      },
    })

    const loader = view.getByRole('status')

    expect(loader).toBeInTheDocument()

    await view.rerender({
      loading: false,
    })

    expect(loader).not.toBeInTheDocument()
  })

  it('renders alert if error prop is supplied', async () => {
    const view = renderComponent(CommonLoader, {
      props: {
        error: 'foobar',
      },
    })

    const alert = view.getByRole('alert')

    expect(alert).toHaveTextContent('foobar')
    expect(getByIconName(alert, 'x-circle')).toBeInTheDocument()
  })

  it('provides default slot', async () => {
    const view = renderComponent(CommonLoader, {
      slots: {
        default: 'foobar',
      },
    })

    expect(view.baseElement).toHaveTextContent('foobar')
    expect(view.queryByRole('status')).not.toBeInTheDocument()
    expect(view.queryByRole('alert')).not.toBeInTheDocument()
  })
})
