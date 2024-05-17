<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'

import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'
import { EnumFormUpdaterId } from '#shared/graphql/types.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import { useEmailOutboundForm } from '#desktop/entities/channel-email/composables/useEmailOutboundForm.ts'
import { useChannelEmailSetNotificationConfigurationMutation } from '#desktop/entities/channel-email/graphql/mutations/channelEmailSetNotificationConfiguration.api.ts'
import { useChannelEmailValidateConfigurationOutboundMutation } from '#desktop/entities/channel-email/graphql/mutations/channelEmailValidateConfigurationOutbound.api.ts'
import type { EmailNotificationData } from '#desktop/entities/channel-email/types/email-notification.ts'
import { useSSLVerificationWarningHandler } from '#desktop/form/composables/useSSLVerificationWarningHandler.ts'

import GuidedSetupActionFooter from '../../components/GuidedSetupActionFooter.vue'
import GuidedSetupStatusMessage from '../../components/GuidedSetupStatusMessage.vue'
import { useSystemSetup } from '../../composables/useSystemSetup.ts'
import { emailBeforeRouteEnterGuard } from '../../router/guards/emailBeforeRouteEnterGuard.ts'

defineOptions({
  beforeRouteEnter: emailBeforeRouteEnterGuard,
})

const router = useRouter()

const { setTitle } = useSystemSetup()
setTitle(__('Email Notification'))

const {
  formEmailOutbound,
  emailOutboundSchema,
  emailOutboundFormChangeFields,
} = useEmailOutboundForm()

const emailNotificationSchema = [
  // For now this is hidden, but should be changeable at some point: https://github.com/zammad/zammad/issues/3343
  {
    name: 'notification_sender',
    label: __('Notification Sender'),
    type: 'hidden',
  },
  ...emailOutboundSchema,
]

const { loading, debouncedLoading } = useDebouncedLoading()

const probeEmailNotification = async (data: EmailNotificationData) => {
  loading.value = true

  const validationConfigurationOutbound = new MutationHandler(
    useChannelEmailValidateConfigurationOutboundMutation(),
  )
  const setNotificationConfiguration = new MutationHandler(
    useChannelEmailSetNotificationConfigurationMutation(),
  )

  const emailOutboundData = {
    adapter: data.adapter,
    host: data.host,
    port: Number(data.port),
    user: data.user,
    password: data.password,
    sslVerify: data.sslVerify,
  }

  return validationConfigurationOutbound
    .send({
      outboundConfiguration: emailOutboundData,
      emailAddress: data.notification_sender,
    })
    .then(async () => {
      const result = await setNotificationConfiguration.send({
        outboundConfiguration: emailOutboundData,
      })

      if (result?.channelEmailSetNotificationConfiguration?.success) {
        router.push('/guided-setup/manual/channels')
      }
    })
    .finally(async () => {
      loading.value = false
    })
}
</script>

<template>
  <GuidedSetupStatusMessage
    v-if="debouncedLoading"
    :message="__('Verifying and saving your configuration…')"
  />
  <div v-show="!debouncedLoading" class="flex flex-col gap-2.5">
    <Form
      id="email-notification-setup"
      ref="formEmailOutbound"
      data-test-id="email-notification-setup"
      form-class="mb-2.5"
      :flatten-form-groups="['outbound']"
      :form-updater-id="
        EnumFormUpdaterId.FormUpdaterUpdaterGuidedSetupEmailNotification
      "
      :schema="emailNotificationSchema"
      :handlers="[useSSLVerificationWarningHandler()]"
      :change-fields="emailOutboundFormChangeFields"
      @submit="
        probeEmailNotification($event as FormSubmitData<EmailNotificationData>)
      "
    />
    <GuidedSetupActionFooter
      go-back-route="/guided-setup/manual/system-information"
      skip-route="/guided-setup/manual/channels"
      :form="formEmailOutbound"
      :submit-button-text="__('Save and Continue')"
    />
  </div>
</template>
