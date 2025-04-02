<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, watch } from 'vue'
import { useRouter } from 'vue-router'

import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { EnumFormUpdaterId } from '#shared/graphql/types.ts'

import { useEmailAccountForm } from '#desktop/entities/channel-email/composables/useEmailAccountForm.ts'
import { useEmailChannelConfiguration } from '#desktop/entities/channel-email/composables/useEmailChannelConfiguration.ts'
import { useEmailInboundForm } from '#desktop/entities/channel-email/composables/useEmailInboundForm.ts'
import { useEmailInboundMessagesForm } from '#desktop/entities/channel-email/composables/useEmailInboundMessagesForm.ts'
import { useEmailOutboundForm } from '#desktop/entities/channel-email/composables/useEmailOutboundForm.ts'
import type { EmailAccountData } from '#desktop/entities/channel-email/types/email-account.ts'
import type {
  EmailInboundData,
  EmailOutboundData,
  EmailInboundMessagesData,
} from '#desktop/entities/channel-email/types/email-inbound-outbound.ts'
import { useArchiveBeforeWarningHandler } from '#desktop/form/composables/useArchiveBeforeWarningHandler.ts'
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

const {
  formEmailAccount,
  emailAccountSchema,
  formEmailAccountValues,
  formEmailAccountSetErrors,
  updateEmailAccountFieldValues,
} = useEmailAccountForm()

const {
  formEmailInbound,
  emailInboundSchema,
  formEmailInboundValues,
  formEmailInboundSetErrors,
  updateEmailInboundFieldValues,
  metaInformationInbound,
  emailInboundFormChangeFields,
  updateMetaInformationInbound,
} = useEmailInboundForm()

const {
  formEmailInboundMessages,
  emailInboundMessageSchema,
  emailInboundMessageSchemaData,
} = useEmailInboundMessagesForm(metaInformationInbound)

const {
  formEmailOutbound,
  emailOutboundSchema,
  formEmailOutboundValues,
  formEmailOutboundSetErrors,
  updateEmailOutboundFieldValues,
  emailOutboundFormChangeFields,
} = useEmailOutboundForm()

const {
  activeStep,
  activeForm,
  stepTitle,
  debouncedLoading,
  guessEmailAccount,
  validateEmailInbound,
  validateEmailOutbound,
  importEmailInboundMessages,
} = useEmailChannelConfiguration(
  {
    emailAccount: {
      form: formEmailAccount,
      values: formEmailAccountValues,
      updateFieldValues: updateEmailAccountFieldValues,
      setErrors: formEmailAccountSetErrors,
    },
    emailInbound: {
      form: formEmailInbound,
      values: formEmailInboundValues,
      setErrors: formEmailInboundSetErrors,
      updateFieldValues: updateEmailInboundFieldValues,
    },
    emailInboundMessages: {
      form: formEmailInboundMessages,
    },
    emailOutbound: {
      form: formEmailOutbound,
      values: formEmailOutboundValues,
      setErrors: formEmailOutboundSetErrors,
      updateFieldValues: updateEmailOutboundFieldValues,
    },
  },
  metaInformationInbound,
  updateMetaInformationInbound,
  () => router.push('/guided-setup/manual/invite'),
)

watch(stepTitle, setTitle, { immediate: true })

const activeInboundMessageNextRoundtrip = computed(
  () =>
    activeStep.value === 'inbound-messages' &&
    metaInformationInbound.value?.nextAction === 'roundtrip',
)

const goBack = () => {
  if (
    activeStep.value === 'inbound' ||
    activeInboundMessageNextRoundtrip.value
  ) {
    activeStep.value = 'account'
  } else if (activeStep.value === 'outbound' && metaInformationInbound.value) {
    activeStep.value = 'inbound-messages'
  } else if (['outbound', 'inbound-messages'].includes(activeStep.value)) {
    activeStep.value = 'inbound'
  } else {
    router.push('/guided-setup/manual/channels')
  }
}

const submitButtonText = computed(() => {
  if (activeStep.value === 'account') {
    return __('Connect and Continue')
  }

  if (
    activeStep.value === 'inbound' ||
    (activeStep.value !== 'outbound' &&
      !activeInboundMessageNextRoundtrip.value)
  ) {
    return __('Continue')
  }

  if (['outbound', 'inbound-messages'].includes(activeStep.value)) {
    return __('Save and Continue')
  }

  return __('Connect and Continue')
})

const submitButtonVariant = computed(() => {
  if (activeStep.value === 'account') {
    return 'submit'
  }

  if (
    activeStep.value === 'inbound' ||
    (activeStep.value !== 'outbound' &&
      !activeInboundMessageNextRoundtrip.value)
  ) {
    return 'primary'
  }

  return 'submit'
})

const emailConfigurationCheck = computed(() => {
  if (activeStep.value === 'account') {
    return __('Verifying and saving your configuration…')
  }

  if (
    activeStep.value === 'inbound' ||
    (activeStep.value !== 'outbound' &&
      !activeInboundMessageNextRoundtrip.value)
  ) {
    return __('Verifying your configuration…')
  }

  return __('Verifying and saving your configuration…')
})
</script>

<template>
  <GuidedSetupStatusMessage
    v-if="debouncedLoading"
    :message="emailConfigurationCheck"
  />
  <div v-show="!debouncedLoading" class="flex flex-col gap-2.5">
    <div v-show="activeStep === 'account'">
      <Form
        id="channel-email-account"
        ref="formEmailAccount"
        data-test-id="channel-email-account"
        form-class="mb-2.5"
        :schema="emailAccountSchema"
        @submit="guessEmailAccount($event as FormSubmitData<EmailAccountData>)"
      />
    </div>
    <div v-show="activeStep === 'inbound'">
      <Form
        id="channel-email-inbound"
        ref="formEmailInbound"
        data-test-id="channel-email-inbound"
        form-class="mb-2.5"
        :handlers="[useSSLVerificationWarningHandler()]"
        :flatten-form-groups="['inbound']"
        :form-updater-id="
          EnumFormUpdaterId.FormUpdaterUpdaterGuidedSetupEmailInbound
        "
        :schema="emailInboundSchema"
        :change-fields="emailInboundFormChangeFields"
        @submit="
          validateEmailInbound($event as FormSubmitData<EmailInboundData>)
        "
      />
    </div>
    <div v-show="activeStep === 'inbound-messages'">
      <Form
        id="channel-email-inbound-messages"
        ref="formEmailInboundMessages"
        data-test-id="channel-email-inbound-messages"
        form-class="mb-2.5"
        :handlers="[useArchiveBeforeWarningHandler()]"
        :form-updater-id="
          EnumFormUpdaterId.FormUpdaterUpdaterGuidedSetupEmailArchive
        "
        :schema="emailInboundMessageSchema"
        :schema-data="emailInboundMessageSchemaData"
        @submit="
          importEmailInboundMessages(
            $event as FormSubmitData<EmailInboundMessagesData>,
          )
        "
      />
    </div>
    <div v-show="activeStep === 'outbound'">
      <Form
        id="channel-email-outbound"
        ref="formEmailOutbound"
        data-test-id="channel-email-outbound"
        form-class="mb-2.5"
        :handlers="[useSSLVerificationWarningHandler()]"
        :flatten-form-groups="['outbound']"
        :form-updater-id="
          EnumFormUpdaterId.FormUpdaterUpdaterGuidedSetupEmailOutbound
        "
        :schema="emailOutboundSchema"
        :change-fields="emailOutboundFormChangeFields"
        @submit="
          validateEmailOutbound($event as FormSubmitData<EmailOutboundData>)
        "
      />
    </div>
    <GuidedSetupActionFooter
      :form="activeForm"
      :submit-button-variant="submitButtonVariant"
      :submit-button-text="submitButtonText"
      @go-back="goBack"
    />
  </div>
</template>
