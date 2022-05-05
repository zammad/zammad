// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

/* eslint-disable import/first */
vi.useFakeTimers().setSystemTime(new Date('2020-10-11T10:10:10Z'))

import CommonDateTime from '@shared/components/CommonDateTime/CommonDateTime.vue'
import { renderComponent } from '@tests/support/components'
import useApplicationStore from '@shared/stores/application'
import { nextTick } from 'vue'

describe('CommonDateTime.vue', () => {
  it('renders DateTime', async () => {
    const wrapper = renderComponent(CommonDateTime, {
      props: {
        dateTime: '2020-10-10T10:10:10Z',
        format: 'absolute',
      },
      store: true,
    })
    expect(wrapper.container).toHaveTextContent('2020-10-10 10:10')
    await wrapper.rerender({ format: 'relative' })
    expect(wrapper.container).toHaveTextContent('1 day ago')

    await wrapper.rerender({ format: 'configured' })
    useApplicationStore().config.pretty_date_format = 'absolute'
    await nextTick()
    expect(wrapper.container).toHaveTextContent('2020-10-10 10:10')

    useApplicationStore().config.pretty_date_format = 'timestamp'
    await nextTick()
    expect(wrapper.container).toHaveTextContent('2020-10-10 10:10')

    useApplicationStore().config.pretty_date_format = 'relative'
    await nextTick()
    expect(wrapper.container).toHaveTextContent('1 day ago')
  })
})
