<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'

import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { autofocusFormField, getNodeId } from '#shared/components/Form/utils.ts'
import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'
import { EnumFormUpdaterId } from '#shared/graphql/types.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { waitForElement } from '#shared/utils/helpers.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useEmailOutboundForm } from '#desktop/entities/channel-email/composables/useEmailOutboundForm.ts'
import { useChannelEmailSetNotificationConfigurationMutation } from '#desktop/entities/channel-email/graphql/mutations/channelEmailSetNotificationConfiguration.api.ts'
import type { EmailNotificationData } from '#desktop/entities/channel-email/types/email-notification.ts'
import { useSSLVerificationWarningHandler } from '#desktop/form/composables/useSSLVerificationWarningHandler.ts'

import GuidedSetupActionFooter from '../../components/GuidedSetupActionFooter.vue'
import GuidedSetupStatusMessage from '../../components/GuidedSetupStatusMessage.vue'
import { useSystemSetup } from '../../composables/useSystemSetup.ts'
import { emailBeforeRouteEnterGuard } from '../../router/guards/emailBeforeRouteEnterGuard.ts'

defineOptions({
  beforeRouteEnter: emailBeforeRouteEnterGuard,
})

const formId = 'email-notification-setup'
const internalOnlyQuestionId = `${formId}-internal-only-question`

const router = useRouter()

const { setTitle } = useSystemSetup()
setTitle(__('Email notification'))

const { user } = storeToRefs(useSessionStore())

const {
  formEmailOutbound,
  emailOutboundSchema,
  emailOutboundFormChangeFields,
  onEmailOutboundChangedField,
} = useEmailOutboundForm({
  smtpFieldsAfterHost: [
    {
      name: 'testAddress',
      label: __('Custom verification email'),
      // No format rule here: the server also takes an address on a host without a domain.
      type: 'email',
      outerClass: 'col-span-2',
      props: {
        maxLength: 120,
      },
      required: true,
      show: false,
      // The form updater only acts on the initial request.
      triggerFormUpdater: false,
      value: user.value?.email,
    },
  ],
})

// The usual check with the external address, the question after the server refused its test email,
//   and the check with the address the admin enters.
type CheckState = 'usual' | 'question' | 'internal-only'

const checkState = ref<CheckState>('usual')

const isInternalOnly = computed(() => checkState.value === 'internal-only')

watch(isInternalOnly, (show) => {
  emailOutboundFormChangeFields.testAddress = { show }
})

// Another server, port or account has to pass the usual check first.
;['adapter', 'host', 'port', 'user', 'password'].forEach((name) => {
  onEmailOutboundChangedField(name, () => {
    checkState.value = 'usual'
  })
})

const confirmInternalOnly = async () => {
  checkState.value = 'internal-only'

  formEmailOutbound.value?.formNode.clearErrors()

  const form = formEmailOutbound.value

  if (!form) return

  const field = await waitForElement(`#${getNodeId(form.formId, 'testAddress')}`)

  if (field) autofocusFormField(field as HTMLElement)
}

const { loading, debouncedLoading } = useDebouncedLoading()

const probeEmailNotification = async (data: EmailNotificationData) => {
  loading.value = true

  if (checkState.value === 'question') checkState.value = 'usual'

  const setNotificationConfiguration = new MutationHandler(
    useChannelEmailSetNotificationConfigurationMutation(),
  )

  // Read here, because the handler turns a payload with errors into an error that only holds those.
  setNotificationConfiguration.operationResult.onDone(({ data }) => {
    if (data?.channelEmailSetNotificationConfiguration?.refused) checkState.value = 'question'
  })

  return setNotificationConfiguration
    .send({
      outboundConfiguration: {
        adapter: data.adapter,
        host: data.host,
        port: Number(data.port),
        user: data.user,
        password: data.password,
        sslVerify: data.sslVerify,
      },
      testAddress: isInternalOnly.value ? data.testAddress : undefined,
    })
    .then((result) => {
      if (result?.channelEmailSetNotificationConfiguration?.success) {
        router.push('/guided-setup/manual/channels')
      }
    })
    .finally(() => {
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
      :id="formId"
      ref="formEmailOutbound"
      data-test-id="email-notification-setup"
      form-class="mb-2.5"
      :flatten-form-groups="['outbound']"
      :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterGuidedSetupEmailNotification"
      :schema="emailOutboundSchema"
      :handlers="[useSSLVerificationWarningHandler()]"
      :change-fields="emailOutboundFormChangeFields"
      @submit="probeEmailNotification($event as FormSubmitData<EmailNotificationData>)"
    >
      <template #before-fields>
        <CommonAlert v-if="checkState === 'question'" class="mb-2.5" variant="info">
          <div class="flex grow flex-col">
            <span :id="internalOnlyQuestionId">{{
              $t('Does this email server only deliver to internal recipients?')
            }}</span>
            <CommonButton
              class="self-end p-0! text-current! underline hover:outline-transparent dark:hover:outline-transparent"
              size="medium"
              :aria-describedby="internalOnlyQuestionId"
              @click="confirmInternalOnly"
            >
              {{ $t('Yes') }}
            </CommonButton>
          </div>
        </CommonAlert>
        <CommonAlert v-if="isInternalOnly" class="mb-2.5" variant="info">
          {{
            $t(
              'Please note that an internal-only email server may fail to deliver password reset, new device and similar system emails to recipients outside the organization.',
            )
          }}
        </CommonAlert>
      </template>
    </Form>
    <GuidedSetupActionFooter
      go-back-route="/guided-setup/manual/system-information"
      skip-route="/guided-setup/manual/channels"
      :form="formEmailOutbound"
      :submit-button-text="__('Save and continue')"
    />
  </div>
</template>
