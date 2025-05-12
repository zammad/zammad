<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, computed, useTemplateRef } from 'vue'

import { useForm } from '#shared/components/Form/useForm.ts'
import { useTwoFactorPlugins } from '#shared/entities/two-factor/composables/useTwoFactorPlugins.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import TwoFactorConfigurationMethodList from './TwoFactorConfiguration/TwoFactorConfigurationMethodList.vue'
import TwoFactorConfigurationPasswordCheck from './TwoFactorConfiguration/TwoFactorConfigurationPasswordCheck.vue'
import TwoFactorConfigurationRecoveryCodes from './TwoFactorConfiguration/TwoFactorConfigurationRecoveryCodes.vue'
import TwoFactorConfigurationWizardFooterActions from './TwoFactorConfigurationWizard/TwoFactorConfigurationWizardFooterActions.vue'

import type {
  TwoFactorConfigurationActionPayload,
  TwoFactorConfigurationComponentInstance,
  TwoFactorConfigurationType,
} from './types.ts'

const props = defineProps<{
  token?: string
}>()

const activeComponentInstance =
  useTemplateRef<TwoFactorConfigurationComponentInstance>('active-component')

const emit = defineEmits<{
  redirect: [url: string]
}>()

const state = ref<TwoFactorConfigurationType>('method_list')

const componentOptions = ref<ObjectLike>()
const localToken = ref(props.token)

const { twoFactorMethodLookup } = useTwoFactorPlugins()

const activeComponent = computed(() => {
  switch (state.value) {
    case 'recovery_codes':
      return TwoFactorConfigurationRecoveryCodes
    case 'password_check':
      return TwoFactorConfigurationPasswordCheck
    case 'method_list':
      if (!localToken.value) return TwoFactorConfigurationPasswordCheck
      return TwoFactorConfigurationMethodList
    default:
      return twoFactorMethodLookup[state.value].configurationOptions?.component
  }
})

const form = computed(() => activeComponentInstance.value?.form)

const { formNodeId, isDisabled: isFormDisabled } = useForm(form)

const footerActionOptions = computed(() => ({
  hideActionButton:
    activeComponentInstance.value?.footerActionOptions?.hideActionButton,
  actionLabel: activeComponentInstance.value?.footerActionOptions?.actionLabel,
  actionButton:
    activeComponentInstance.value?.footerActionOptions?.actionButton,
  hideCancelButton:
    activeComponentInstance.value?.footerActionOptions?.hideCancelButton,
  cancelLabel:
    activeComponentInstance.value?.footerActionOptions?.cancelLabel ||
    __('Go Back'),
  cancelButton:
    activeComponentInstance.value?.footerActionOptions?.cancelButton,
}))

const handleActionPayload = (payload: TwoFactorConfigurationActionPayload) => {
  if (!payload?.nextState) {
    emit('redirect', '/')
    return
  }

  state.value = payload.nextState
  localToken.value = payload.token ?? localToken.value
  componentOptions.value = payload.options
}

const onFooterButtonAction = () => {
  if (activeComponentInstance.value?.form) return
  activeComponentInstance.value
    ?.executeAction?.()
    .then((payload) => handleActionPayload(payload))
    .catch(() => {})
}

const cancel = () => {
  if (state.value === 'method_list') {
    emit('redirect', '/logout')
    return
  }

  state.value = 'method_list'
}
</script>

<template>
  <div class="mb-8">
    <component
      :is="activeComponent"
      ref="active-component"
      :type="state"
      :options="componentOptions"
      :token="localToken"
      :form-submit-callback="handleActionPayload"
    />
  </div>
  <div class="flex flex-col gap-3">
    <TwoFactorConfigurationWizardFooterActions
      v-bind="footerActionOptions"
      :form-node-id="formNodeId"
      :is-form-disabled="isFormDisabled"
      @action="onFooterButtonAction()"
      @cancel="cancel()"
    />
  </div>
</template>
