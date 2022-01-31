// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import CommonNotifications from '@common/components/common/CommonNotifications.vue'
import { Story } from '@storybook/vue3'
import useNotifications from '@common/composables/useNotifications'
import { NotificationTypes } from '@common/types/notification'

export default {
  title: 'Common/Notifications',
  component: CommonNotifications,
  args: {
    durationMS: '5000',
    persistent: false,
    message: 'This is a notification message.',
  },
  argTypes: {
    type: {
      control: { type: 'select' },
      options: [
        NotificationTypes.ERROR,
        NotificationTypes.WARN,
        NotificationTypes.SUCCESS,
        NotificationTypes.INFO,
      ],
    },
  },
}

const { notify } = useNotifications()

const Template: Story = (args) => ({
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
    '<button class="bg-white hover:bg-gray-100 text-gray-800 py-2 px-4 border border-gray-400 rounded text-sm" v-on:click="showNotification()">Show notification</button><CommonNotifications />',
})

export const WarnNotification = Template.bind({})
WarnNotification.args = { type: NotificationTypes.WARN }

export const ErrorNotification = Template.bind({})
ErrorNotification.args = { type: NotificationTypes.ERROR }

export const SuccessNotification = Template.bind({})
SuccessNotification.args = { type: NotificationTypes.SUCCESS }

export const InfoNotification = Template.bind({})
InfoNotification.args = { type: NotificationTypes.INFO }

export const CallbackNotification = Template.bind({})
CallbackNotification.args = {
  type: NotificationTypes.INFO,
  persistent: true,
  callback: () => {
    // eslint-disable-next-line no-alert
    window.alert('Callback executed.')
  },
}
