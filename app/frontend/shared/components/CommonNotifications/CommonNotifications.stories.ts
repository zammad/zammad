// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import { useNotifications, NotificationTypes, type Notification } from '.'
import CommonNotifications from './CommonNotifications.vue'

export default {
  title: 'Shared/Notifications',
  component: CommonNotifications,
  args: {
    // No real props, notifications are triggered with a composable function.
    durationMS: '5000',
    persistent: false,
    message: 'This is a notification message.',
  },
  argTypes: {
    type: {
      control: { type: 'select' },
      options: [
        NotificationTypes.Error,
        NotificationTypes.Warn,
        NotificationTypes.Success,
        NotificationTypes.Info,
      ],
    },
  },
  parameters: {
    durationMS: 5000,
  },
}

const { notify } = useNotifications()

const Template: Story<Notification> = (args: Notification) => ({
  components: { CommonNotifications },
  setup() {
    return { args }
  },
  methods: {
    showNotification() {
      notify({
        message: args.message,
        type: args.type,
        durationMS: args.durationMS,
        callback: args.callback,
      })
    },
  },
  template:
    '<button class="bg-white hover:bg-gray-300 text-gray-600 py-2 px-4 border border-gray-600 rounded text-sm" v-on:click="showNotification()">Show notification</button><CommonNotifications />',
})

export const WarnNotification = Template.bind({})
WarnNotification.args = { type: NotificationTypes.Warn }

export const ErrorNotification = Template.bind({})
ErrorNotification.args = { type: NotificationTypes.Error }

export const SuccessNotification = Template.bind({})
SuccessNotification.args = { type: NotificationTypes.Success }

export const InfoNotification = Template.bind({})
InfoNotification.args = { type: NotificationTypes.Info }

export const CallbackNotification = Template.bind({})
CallbackNotification.args = {
  type: NotificationTypes.Info,
  persistent: true,
  callback: () => {
    // eslint-disable-next-line no-alert
    window.alert('Callback executed.')
  },
}
