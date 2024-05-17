// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonLabel from '../CommonLabel.vue'

describe('CommonLabel.vue', () => {
  it('renders when no props are passed', () => {
    const view = renderComponent(CommonLabel, {
      slots: {
        default: 'Dummy',
      },
    })

    const label = view.getByTestId('common-label')

    expect(label).toHaveTextContent('Dummy')
    expect(label).toHaveClass('text-sm')
  })

  it('renders bigger text if size is given', () => {
    const view = renderComponent(CommonLabel, {
      props: {
        size: 'large',
      },
      slots: {
        default: 'Dummy',
      },
    })

    const label = view.getByTestId('common-label')

    expect(label).toHaveTextContent('Dummy')
    expect(label).toHaveClass('text-base')
  })

  it('renders icons (prefix + suffix)', () => {
    const view = renderComponent(CommonLabel, {
      props: {
        prefixIcon: 'web',
        suffixIcon: 'web',
      },
      slots: {
        default: 'Dummy',
      },
    })

    const label = view.getByTestId('common-label')

    expect(label).toHaveTextContent('Dummy')
    expect(view.getAllByIconName('web')).toHaveLength(2)
  })
})
