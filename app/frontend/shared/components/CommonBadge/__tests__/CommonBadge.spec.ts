// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonBadge from '../CommonBadge.vue'

describe('CommonLabel.vue', () => {
  it('renders when no props are passed', () => {
    const view = renderComponent(CommonBadge, {
      slots: {
        default: 'Dummy',
      },
    })

    const badge = view.getByTestId('common-badge')

    expect(badge).toHaveTextContent('Dummy')
    expect(badge).toHaveClass('text-xs')
  })

  it('renders bigger text if size is given', () => {
    const view = renderComponent(CommonBadge, {
      props: {
        size: 'large',
      },
      slots: {
        default: 'Dummy',
      },
    })

    const badge = view.getByTestId('common-badge')

    expect(badge).toHaveTextContent('Dummy')
    expect(badge).toHaveClass('text-base')
  })

  it('renders correct colors if variant is given', () => {
    const view = renderComponent(CommonBadge, {
      props: {
        variant: 'success',
      },
      slots: {
        default: 'Dummy',
      },
    })

    const badge = view.getByTestId('common-badge')

    expect(badge).toHaveTextContent('Dummy')
    expect(badge).toHaveClasses([
      'common-badge',
      'common-badge-success',
      'text-xs',
    ])
  })

  it('renders correct colors if variant custom is given', () => {
    const view = renderComponent(CommonBadge, {
      props: {
        variant: 'custom',
        class: ['dark:bg-pink-300', 'bg-pink-300', 'text-white'],
      },
      slots: {
        default: 'Dummy',
      },
    })

    const badge = view.getByTestId('common-badge')

    expect(badge).toHaveTextContent('Dummy')
    expect(badge).toHaveClasses([
      'text-xs',
      'dark:bg-pink-300',
      'bg-pink-300',
      'text-white',
    ])
  })
})
