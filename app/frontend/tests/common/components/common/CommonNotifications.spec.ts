// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { VueWrapper } from '@vue/test-utils'
import { ComponentPublicInstance, nextTick } from 'vue'
import CommonNotifications from '@common/components/common/CommonNotifications.vue'
import { NotificationTypes } from '@common/types/notification'
import useNotifications from '@/common/composables/useNotifications'
import { getWrapper } from '@tests/support/components'

let wrapper: VueWrapper<ComponentPublicInstance>

const message = 'Test Notification'
beforeEach(() => {
  const { clearAllNotifications } = useNotifications()
  clearAllNotifications()

  wrapper = getWrapper(CommonNotifications, { shallow: false })
})

describe('CommonNotifications.vue', () => {
  it('renders notification with passed message', async () => {
    expect.assertions(2)
    const { notify } = useNotifications()
    await notify({
      message,
      type: NotificationTypes.WARN,
    })

    expect(wrapper.find('span').exists()).toBeTruthy()
    expect(wrapper.get('span').text()).toBe(message)
  })

  it('automatically removes notification after timeout', async () => {
    expect.assertions(1)

    const { notify } = useNotifications()

    await notify({
      message,
      type: NotificationTypes.WARN,
      duration: 2000,
    })

    await new Promise((resolve) => {
      setTimeout(resolve, 2100)
    })
    expect(wrapper.find('span').exists()).toBeFalsy()
  })

  it('renders multiple notifications at the same time', async () => {
    expect.assertions(1)

    const { notify, notifications } = useNotifications()

    await notify({
      message: `${message} - ${notifications.value.length}`,
      type: NotificationTypes.WARN,
    })

    await notify({
      message: `${message} - ${notifications.value.length}`,
      type: NotificationTypes.WARN,
    })

    await notify({
      message: `${message} - ${notifications.value.length}`,
      type: NotificationTypes.WARN,
    })

    expect(wrapper.findAll('span')).toHaveLength(3)
  })

  it('clears all notifications', async () => {
    expect.assertions(2)
    const { notify, notifications, clearAllNotifications } = useNotifications()

    await notify({
      message: `${message} - ${notifications.value.length}`,
      type: NotificationTypes.WARN,
    })

    await notify({
      message: `${message} - ${notifications.value.length}`,
      type: NotificationTypes.WARN,
    })

    await notify({
      message: `${message} - ${notifications.value.length}`,
      type: NotificationTypes.WARN,
    })

    clearAllNotifications()
    await nextTick()
    expect(notifications.value.length).toBe(0)
    expect(wrapper.find('span').exists()).toBeFalsy()
  })

  it('renders notification with icon', async () => {
    expect.assertions(1)
    const { notify } = useNotifications()
    await notify({
      message,
      type: NotificationTypes.WARN,
    })

    expect(wrapper.find('.icon').exists()).toBeTruthy()
  })
})
