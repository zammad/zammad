// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import CommonNotifications from '@common/components/common/CommonNotifications.vue'
import { Story } from '@storybook/vue3'
import useNotifications from '@common/composables/useNotifications'
import { NotificationTypes } from '@common/types/notification'

export default {
  title: 'Common/Notifications',
  component: CommonNotifications,
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
        message: "I'm inside a story",
        type: args.type,
      })
    },
  },
  template:
    '<button class="bg-white hover:bg-gray-100 text-gray-800 py-2 px-4 border border-gray-400 rounded text-sm" @click="showNotification()">Show notification</button><CommonNotifications v-bind="args" />',
})

export const WarnNotification = Template.bind({})
WarnNotification.args = { type: NotificationTypes.WARN }

export const ErrorNotification = Template.bind({})
ErrorNotification.args = { type: NotificationTypes.ERROR }

export const SuccessNotification = Template.bind({})
SuccessNotification.args = { type: NotificationTypes.SUCCESS }

export const InfoNotification = Template.bind({})
InfoNotification.args = { type: NotificationTypes.INFO }
