// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

/* eslint-disable import/first */
// Set fake time before starting the internal i18n 'reactiveNow' timer.
jest.useFakeTimers().setSystemTime(new Date('2020-10-11T10:10:10Z'))

import CommonDateTime from '@common/components/common/CommonDateTime.vue'
import { getWrapper } from '@tests/support/components'
import useApplicationConfigStore from '@common/stores/application/config'
import { nextTick } from 'vue'

describe('CommonDateTime.vue', () => {
  it('renders DateTime', async () => {
    expect.assertions(5)
    const wrapper = getWrapper(CommonDateTime, {
      props: {
        dateTime: '2020-10-10T10:10:10Z',
        format: 'absolute',
      },
      store: true,
    })
    expect(wrapper.find('span').text()).toBe('2020-10-10 10:10')
    wrapper.setProps({ format: 'relative' })
    await nextTick()
    expect(wrapper.find('span').text()).toBe('1 day ago')

    wrapper.setProps({ format: 'configured' })
    useApplicationConfigStore().value.pretty_date_format = 'absolute'
    await nextTick()
    expect(wrapper.find('span').text()).toBe('2020-10-10 10:10')

    useApplicationConfigStore().value.pretty_date_format = 'timestamp'
    await nextTick()
    expect(wrapper.find('span').text()).toBe('2020-10-10 10:10')

    useApplicationConfigStore().value.pretty_date_format = 'relative'
    await nextTick()
    expect(wrapper.find('span').text()).toBe('1 day ago')
  })
})
