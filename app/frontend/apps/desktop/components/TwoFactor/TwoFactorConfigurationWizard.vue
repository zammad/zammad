<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, computed, useTemplateRef } from 'vue'

import { useTwoFactorPlugins } from '#shared/entities/two-factor/composables/useTwoFactorPlugins.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import TwoFactorConfigurationMethodList from './TwoFactorConfiguration/TwoFactorConfigurationMethodList.vue'
import TwoFactorConfigurationRecoveryCodes from './TwoFactorConfiguration/TwoFactorConfigurationRecoveryCodes.vue'
import TwoFactorConfigurationWizardFooterActions from './TwoFactorConfigurationWizard/TwoFactorConfigurationWizardFooterActions.vue'

import type {
  TwoFactorConfigurationActionPayload,
  TwoFactorConfigurationComponentInstance,
  TwoFactorConfigurationType,
} from './types.ts'

const activeComponentInstance =
  useTemplateRef<TwoFactorConfigurationComponentInstance>('active-component')

const emit = defineEmits<{
  redirect: [url: string]
}>()

const state = ref<TwoFactorConfigurationType>('method_list')
const componentOptions = ref<ObjectLike>()

const { twoFactorMethodLookup } = useTwoFactorPlugins()

const activeComponent = computed(() => {
  switch (state.value) {
    case 'recovery_codes':
      return TwoFactorConfigurationRecoveryCodes
    case 'method_list':
      return TwoFactorConfigurationMethodList
    default:
      return twoFactorMethodLookup[state.value].configurationOptions?.component
  }
})

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
  form: activeComponentInstance.value?.footerActionOptions?.form,
}))

const handleActionPayload = (payload: TwoFactorConfigurationActionPayload) => {
  if (!payload?.nextState) {
    emit('redirect', '/')
    return
  }

  state.value = payload.nextState
  componentOptions.value = payload.options
}

const onFooterButtonAction = () => {
  if (activeComponentInstance.value?.footerActionOptions?.form) return
  activeComponentInstance.value
    ?.executeAction?.()
    .then((payload) => handleActionPayload(payload))
    .catch(() => {})
}

const successCallback = () => {
  console.debug('successCallback')
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
      :form-submit-callback="handleActionPayload"
      :success-callback="successCallback"
    />
  </div>
  <div class="flex flex-col gap-3">
    <TwoFactorConfigurationWizardFooterActions
      v-bind="footerActionOptions"
      @action="onFooterButtonAction()"
      @cancel="cancel()"
    />
  </div>
</template>
