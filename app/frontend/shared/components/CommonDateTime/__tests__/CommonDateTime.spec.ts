// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

vi.useFakeTimers().setSystemTime(new Date('2020-10-11T10:10:10Z'))

import { nextTick } from 'vue'
import { renderComponent } from '@tests/support/components'
import { useApplicationStore } from '@shared/stores/application'
import CommonDateTime, { type Props } from '../CommonDateTime.vue'

const dateTime = '2020-10-10T10:10:10Z'
const renderDateTime = (props: Props) => {
  return renderComponent(CommonDateTime, {
    props: {
      ...props,
    },
    store: true,
  })
}

describe('CommonDateTime.vue', () => {
  it('renders with type relative', async () => {
    const view = renderDateTime({ dateTime, type: 'relative' })
    expect(view.container).toHaveTextContent('1 day ago')
  })

  it('renders with type absolute + absolute format "datetime" (default)', async () => {
    const view = renderDateTime({
      dateTime,
      type: 'absolute',
    })
    expect(view.container).toHaveTextContent('2020-10-10 10:10')
  })

  it('renders with type absolute + absolute format "datetime" (set via prop)', async () => {
    const view = renderDateTime({
      dateTime,
      type: 'absolute',
      absoluteFormat: 'datetime',
    })
    expect(view.container).toHaveTextContent('2020-10-10 10:10')
  })

  it('renders with type absolute + absolute format "date"', async () => {
    const view = renderDateTime({
      dateTime,
      type: 'absolute',
      absoluteFormat: 'date',
    })
    expect(view.container).toHaveTextContent('2020-10-10')
  })

  it('renders with type absolute (application store)', async () => {
    const view = renderDateTime({ dateTime, type: 'absolute' })
    useApplicationStore().config.pretty_date_format = 'absolute'
    await nextTick()
    expect(view.container).toHaveTextContent('2020-10-10')
  })

  it('renders with type configured + absolute format "date" (application store)', async () => {
    const view = renderDateTime({ dateTime, type: 'configured' })
    useApplicationStore().config.pretty_date_format = 'absolute'
    await nextTick()
    expect(view.container).toHaveTextContent('2020-10-10')
  })

  it('renders with type timestamp (application store)', async () => {
    const view = renderDateTime({ dateTime, type: 'configured' })
    useApplicationStore().config.pretty_date_format = 'timestamp'
    await nextTick()
    expect(view.container).toHaveTextContent('2020-10-10 10:10')
  })

  it('renders with type relative (application store)', async () => {
    const view = renderDateTime({ dateTime, type: 'configured' })
    useApplicationStore().config.pretty_date_format = 'relative'
    await nextTick()
    expect(view.container).toHaveTextContent('1 day ago')
  })
})
