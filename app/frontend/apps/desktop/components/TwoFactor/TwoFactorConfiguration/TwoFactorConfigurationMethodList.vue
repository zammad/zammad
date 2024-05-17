<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useApplicationConfigTwoFactor } from '#shared/composables/authentication/useApplicationConfigTwoFactor.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import type {
  TwoFactorConfigurationComponentProps,
  TwoFactorConfigurationType,
} from '../types.ts'

const props = defineProps<TwoFactorConfigurationComponentProps>()

const { twoFactorEnabledMethods } = useApplicationConfigTwoFactor()

const { hasPermission } = useSessionStore()

const switchTo = (nextState: TwoFactorConfigurationType) => {
  props.formSubmitCallback?.({ nextState })
}

const footerActionOptions = computed(() => ({
  hideActionButton: true,
  cancelLabel: __('Cancel & Sign Out'),
}))

defineExpose({
  footerActionOptions,
})
</script>

<template>
  <div class="text-center">
    <template
      v-if="hasPermission('user_preferences.two_factor_authentication')"
    >
      <CommonLabel class="mb-3">{{
        $t('You must protect your account with two-factor authentication.')
      }}</CommonLabel>
      <CommonLabel class="mb-3">{{
        $t(
          'Choose your preferred two-factor authentication method to set it up.',
        )
      }}</CommonLabel>
      <section
        v-for="method of twoFactorEnabledMethods"
        :key="method.name"
        class="mt-3 flex flex-col"
      >
        <CommonButton
          size="large"
          block
          :prefix-icon="method.icon"
          variant="primary"
          @click="switchTo(method.name)"
        >
          {{ $t(method.label) }}
        </CommonButton>

        <div v-if="method.description" class="mt-2.5 text-center">
          <CommonLabel>
            {{ $t(method.description) }}
          </CommonLabel>
        </div>
      </section>
    </template>
    <CommonAlert v-else variant="danger">{{
      $t(
        "Two-factor authentication is required, but you don't have sufficient permissions to set it up. Please contact your administrator.",
      )
    }}</CommonAlert>
  </div>
</template>
