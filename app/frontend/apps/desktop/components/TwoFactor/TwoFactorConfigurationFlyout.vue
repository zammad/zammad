<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, computed } from 'vue'

import { useTwoFactorPlugins } from '#shared/entities/two-factor/composables/useTwoFactorPlugins.ts'
import { i18n } from '#shared/i18n.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'

import TwoFactorConfigurationPasswordCheck from './TwoFactorConfiguration/TwoFactorConfigurationPasswordCheck.vue'
import TwoFactorConfigurationRecoveryCodes from './TwoFactorConfiguration/TwoFactorConfigurationRecoveryCodes.vue'

import type {
  TwoFactorConfigurationActionPayload,
  TwoFactorConfigurationComponentInstance,
  TwoFactorConfigurationProps,
  TwoFactorConfigurationType,
} from './types.ts'

const props = defineProps<TwoFactorConfigurationProps>()

const activeComponentInstance = ref<TwoFactorConfigurationComponentInstance>()

const headerTitle = computed(() => {
  switch (props.type) {
    case 'recovery_codes':
      return i18n.t(
        'Generate Recovery Codes: %s',
        i18n.t(activeComponentInstance.value?.headerSubtitle),
      )
    case 'removal_confirmation':
      return i18n.t(
        'Remove Two-factor Authentication: %s',
        i18n.t(activeComponentInstance.value?.headerSubtitle),
      )
    default:
      return i18n.t(
        'Set Up Two-factor Authentication: %s',
        i18n.t(activeComponentInstance.value?.headerSubtitle),
      )
  }
})

const state = ref<TwoFactorConfigurationType>('password_check')
const componentOptions = ref<ObjectLike>()

const { twoFactorMethodLookup } = useTwoFactorPlugins()

const activeComponent = computed(() => {
  switch (state.value) {
    case 'recovery_codes':
      return TwoFactorConfigurationRecoveryCodes
    case 'password_check':
    case 'removal_confirmation':
      return TwoFactorConfigurationPasswordCheck
    default:
      return twoFactorMethodLookup[state.value].configurationOptions?.component
  }
})

const handleActionPayload = (payload: TwoFactorConfigurationActionPayload) => {
  if (!payload?.nextState) {
    closeFlyout('two-factor-flyout')
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
</script>

<template>
  <CommonFlyout
    :header-title="headerTitle"
    :footer-action-options="activeComponentInstance?.footerActionOptions"
    :header-icon="activeComponentInstance?.headerIcon"
    name="two-factor-flyout"
    no-close-on-action
    @action="onFooterButtonAction"
  >
    <component
      :is="activeComponent"
      ref="activeComponentInstance"
      :type="type"
      :options="componentOptions"
      :form-submit-callback="handleActionPayload"
      :success-callback="successCallback"
    />
  </CommonFlyout>
</template>
