// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import CommonLoader from '../CommonLoader.vue'

describe('CommonLoader.vue', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterAll(() => {
    vi.useRealTimers()
  })

  it('does not render with default prop values', async () => {
    const wrapper = renderComponent(CommonLoader)

    expect(wrapper.queryByRole('status')).not.toBeInTheDocument()
  })

  it('hides loading animation when loading prop is unset', async () => {
    const wrapper = renderComponent(CommonLoader, {
      props: {
        loading: true,
      },
    })

    vi.advanceTimersByTime(300)

    const loader = await wrapper.findAllByRole('progressbar')

    expect(loader).toHaveLength(3)

    await wrapper.rerender({
      loading: false,
    })

    await waitForNextTick()

    expect(wrapper.queryByRole('progressbar')).not.toBeInTheDocument()
  })

  it('renders alert if error prop is supplied', async () => {
    const wrapper = renderComponent(CommonLoader, {
      props: {
        error: 'foobar',
      },
    })

    const alert = wrapper.getByRole('alert')

    expect(alert).toHaveTextContent('foobar')
    expect(getByIconName(alert, 'x-circle')).toBeInTheDocument()
  })

  it('provides default slot', async () => {
    const wrapper = renderComponent(CommonLoader, {
      slots: {
        default: 'foobar',
      },
    })

    expect(wrapper.baseElement).toHaveTextContent('foobar')
    expect(wrapper.queryByRole('status')).not.toBeInTheDocument()
    expect(wrapper.queryByRole('alert')).not.toBeInTheDocument()
  })
})
