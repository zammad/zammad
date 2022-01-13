// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import CommonHelloWorld from '@common/components/common/CommonHelloWorld.vue'
import { getWrapper } from '@tests/support/components'

describe('CommonHelloWorld.vue', () => {
  it('renders props.msg when passed', () => {
    const msg = 'new message'
    const i18n = {
      t(source: string) {
        return source
      },
    }
    const wrapper = getWrapper(CommonHelloWorld, {
      props: { msg, show: true },
      global: {
        mocks: {
          i18n,
        },
      },
    })
    expect(wrapper.text()).toMatch(msg)
  })
})
