// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick } from 'vue'

import { renderComponent, type ExtendedRenderResult } from '#tests/support/components/index.ts'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'

import CommonNotifications from '../CommonNotifications.vue'

let wrapper: ExtendedRenderResult

const message = 'Test Notification'

beforeEach(() => {
  vi.useFakeTimers()

  const { clearAllNotifications } = useNotifications()
  clearAllNotifications()

  wrapper = renderComponent(CommonNotifications, { shallow: false })
})

afterEach(() => {
  vi.useRealTimers()
})

describe('CommonNotifications.vue', () => {
  it('renders notification with passed message', async () => {
    const { notify } = useNotifications()

    notify({
      message,
      type: NotificationTypes.Warn,
    })

    await nextTick()

    const notification = wrapper.getByRole('alert')

    expect(notification).toBeInTheDocument()
    expect(wrapper.getByTestId('notification')).toBeInTheDocument()
  })

  it('automatically removes non-persistent notifications after timeout', async () => {
    const { notify } = useNotifications()

    notify({
      message,
      type: NotificationTypes.Warn,
      durationMS: 10,
    })

    await nextTick()

    expect(wrapper.getByTestId('notification')).toBeInTheDocument()

    await vi.advanceTimersByTimeAsync(11)
    await nextTick()

    expect(wrapper.queryByTestId('notification')).not.toBeInTheDocument()
  })

  it('does not remove persistent notifications', async () => {
    const { notify } = useNotifications()

    notify({
      message,
      type: NotificationTypes.Warn,
      durationMS: 10,
      persistent: true,
    })

    vi.advanceTimersByTime(20)

    await nextTick()

    expect(wrapper.getByTestId('notification')).toBeInTheDocument()
  })

  it('executes callback and removes notification on click', async () => {
    const { notify } = useNotifications()
    const closeCallback = vi.fn()

    notify({
      message,
      type: NotificationTypes.Warn,
      closeCallback,
    })

    await nextTick()
    await wrapper.events.click(wrapper.getByTestId('notification'))

    expect(closeCallback).toHaveBeenCalledTimes(1)
    expect(wrapper.queryByTestId('notification')).not.toBeInTheDocument()
  })

  it('triggers notification callback on Enter keydown', async () => {
    const { notify } = useNotifications()
    const closeCallback = vi.fn()

    notify({
      message,
      type: NotificationTypes.Warn,
      closeCallback,
    })

    await nextTick()

    const notification = wrapper.getByRole('button')

    notification.focus()

    await wrapper.events.keyboard('{Enter}')

    expect(closeCallback).toHaveBeenCalledTimes(2)

    expect(wrapper.queryByTestId('notification')).not.toBeInTheDocument()
  })

  it('does not trigger callback on non-Enter keydown', async () => {
    const { notify } = useNotifications()
    const closeCallback = vi.fn()

    notify({
      message,
      type: NotificationTypes.Warn,
      closeCallback,
      persistent: true,
    })
    await nextTick()

    const notification = wrapper.getByTestId('notification')

    notification.focus()
    await wrapper.events.keyboard('{Escape}')

    expect(closeCallback).not.toHaveBeenCalled()
    expect(wrapper.getByTestId('notification')).toBeInTheDocument()
  })

  it('renders multiple notifications at the same time', async () => {
    const { notify, notifications } = useNotifications()

    notify({
      message: `${message} - ${notifications.value.length}`,
      type: NotificationTypes.Warn,
    })

    notify({
      message: `${message} - ${notifications.value.length}`,
      type: NotificationTypes.Warn,
    })

    notify({
      message: `${message} - ${notifications.value.length}`,
      type: NotificationTypes.Warn,
    })
    await nextTick()

    expect(wrapper.getAllByTestId('notification')).toHaveLength(3)
  })

  it('replaces duplicate id when unique is true', async () => {
    const { notify } = useNotifications()

    notify({
      id: 'same-id',
      message: `${message} - first`,
      type: NotificationTypes.Warn,
      persistent: true,
    })

    notify({
      id: 'same-id',
      message: `${message} - second`,
      type: NotificationTypes.Success,
      persistent: true,
      unique: true,
    })
    await nextTick()

    const notifications = wrapper.getAllByTestId('notification')
    expect(notifications).toHaveLength(1)
  })

  it('keeps duplicate id when unique is false', async () => {
    const { notify } = useNotifications()

    notify({
      id: 'same-id',
      message: `${message} - first`,
      type: NotificationTypes.Warn,
      persistent: true,
    })

    notify({
      id: 'same-id',
      message: `${message} - second`,
      type: NotificationTypes.Success,
      persistent: true,
      unique: false,
    })
    await nextTick()

    expect(wrapper.getAllByTestId('notification')).toHaveLength(2)
  })

  it('clears all notifications and state', async () => {
    const { notify, notifications, clearAllNotifications, hasErrors } = useNotifications()

    notify({
      message: `${message} - ${notifications.value.length}`,
      type: NotificationTypes.Warn,
    })

    notify({
      message: `${message} - ${notifications.value.length}`,
      type: NotificationTypes.Warn,
    })

    notify({
      message: `${message} - ${notifications.value.length}`,
      type: NotificationTypes.Error,
    })
    await nextTick()

    expect(hasErrors()).toBe(true)

    clearAllNotifications()
    await nextTick()

    expect(notifications.value).toHaveLength(0)
    expect(hasErrors()).toBe(false)
    expect(wrapper.queryAllByTestId('notification')).toHaveLength(0)
  })

  it('renders notification icon', async () => {
    const { notify } = useNotifications()

    notify({
      message,
      type: NotificationTypes.Warn,
    })
    await nextTick()

    expect(wrapper.getByIconName('info')).toBeInTheDocument()
  })

  describe('Progress Bar', () => {
    it('renders progress bar when progress value is provided', async () => {
      const { notify } = useNotifications()

      notify({
        message,
        type: NotificationTypes.Warn,
        currentProgress: 0.5,
      })
      await nextTick()

      const progressBar = wrapper.getByRole('progressbar')
      expect(progressBar).toBeInTheDocument()
    })

    it('displays correct progress value', async () => {
      const { notify } = useNotifications()
      const progressValue = 0.75

      notify({
        message,
        type: NotificationTypes.Warn,
        currentProgress: progressValue,
      })
      await nextTick()

      const progressBar = wrapper.getByRole('progressbar')
      expect(progressBar).toHaveAttribute('value', '0.75')
    })

    it('renders close button for persistent notification', async () => {
      const { notify } = useNotifications()

      notify({
        message,
        type: NotificationTypes.Warn,
        persistent: true,
      })
      await nextTick()

      const hideButton = wrapper.getByRole('button', { name: 'Hide notification' })

      expect(hideButton).toHaveTextContent('Hide')
    })

    it('removes notification when close button is clicked', async () => {
      const { notify } = useNotifications()

      notify({
        message,
        type: NotificationTypes.Warn,
        currentProgress: 0.5,
        persistent: true,
      })
      await nextTick()

      expect(wrapper.getByTestId('notification')).toBeInTheDocument()

      const closeButton = wrapper.getByRole('button')
      await wrapper.events.click(closeButton)

      expect(wrapper.queryByTestId('notification')).not.toBeInTheDocument()
    })

    it('does not make notification clickable when progress is shown', async () => {
      const { notify } = useNotifications()
      const closeCallback = vi.fn()

      notify({
        message,
        type: NotificationTypes.Warn,
        currentProgress: 0.5,
        closeCallback,
        persistent: true,
      })
      await nextTick()

      const notification = wrapper.getByTestId('notification')
      expect(notification).not.toHaveAttribute('role', 'button')
      expect(notification).not.toHaveAttribute('tabindex')

      await wrapper.events.click(notification)

      expect(closeCallback).not.toHaveBeenCalled()
      expect(wrapper.getByTestId('notification')).toBeInTheDocument()
    })

    it('updates progress value when notification changes', async () => {
      const { notify, notifications } = useNotifications()

      const notificationId = notify({
        message,
        type: NotificationTypes.Warn,
        persistent: true,
        currentProgress: 0.25,
      })
      await nextTick()

      let progressBar = wrapper.getByRole('progressbar')
      expect(progressBar).toHaveAttribute('value', '0.25')

      // Update notification progress
      const notification = notifications.value.find((n) => n.id === notificationId)
      if (notification) {
        notification.currentProgress = 0.75
      }

      await nextTick()

      progressBar = wrapper.getByRole('progressbar')
      expect(progressBar).toHaveAttribute('value', '0.75')
    })

    it('renders multiple notifications with different progress values', async () => {
      const { notify } = useNotifications()

      notify({
        message: `${message} - 1`,
        type: NotificationTypes.Warn,
        persistent: true,
        currentProgress: 0.25,
      })

      notify({
        message: `${message} - 2`,
        type: NotificationTypes.Success,
        persistent: true,
        currentProgress: 0.5,
      })

      notify({
        message: `${message} - 3`,
        type: NotificationTypes.Error,
        persistent: true,
        currentProgress: 0.75,
      })
      await nextTick()

      const progressBars = wrapper.getAllByRole('progressbar')
      expect(progressBars).toHaveLength(3)
      expect(progressBars[0]).toHaveAttribute('value', '0.25')
      expect(progressBars[1]).toHaveAttribute('value', '0.5')
      expect(progressBars[2]).toHaveAttribute('value', '0.75')
    })

    it('does not auto-remove persistent notifications with progress', async () => {
      vi.useFakeTimers()

      const { notify } = useNotifications()

      notify({
        message,
        type: NotificationTypes.Warn,
        currentProgress: 0.5,
        persistent: true,
        durationMS: 10,
      })
      await nextTick()

      await vi.advanceTimersByTimeAsync(20)
      await nextTick()

      expect(wrapper.getByTestId('notification')).toBeInTheDocument()
    })
  })
})
