<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onBeforeMount, ref } from 'vue'

import { useCopyToClipboard } from '#shared/composables/useCopyToClipboard.ts'
import { useUserCurrentTwoFactorRecoveryCodesGenerateMutation } from '#shared/entities/user/current/graphql/mutations/two-factor/userCurrentTwoFactorRecoveryCodesGenerate.api.ts'
import UserError from '#shared/errors/UserError.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { usePrintMode } from '#desktop/composables/usePrintMode.ts'

import type { TwoFactorConfigurationComponentProps } from '../types.ts'

const props = defineProps<TwoFactorConfigurationComponentProps>()

const headerSubtitle = __('Save Codes')

const headerIcon = computed(() => props.options?.headerIcon ?? 'shield-lock')

const loading = ref(false)
const error = ref('')
const recoveryCodes = ref<string[] | null | undefined>(
  props.options?.recoveryCodes,
)

onBeforeMount(async () => {
  if (props.options?.recoveryCodes) return

  loading.value = true

  const recoveryCodesGenerate = new MutationHandler(
    useUserCurrentTwoFactorRecoveryCodesGenerateMutation(),
    {
      errorNotificationMessage: __('Could not generate recovery codes'),
    },
  )

  recoveryCodesGenerate
    .send()
    .then((data) => {
      recoveryCodes.value =
        data?.userCurrentTwoFactorRecoveryCodesGenerate?.recoveryCodes
    })
    .catch((err) => {
      if (err instanceof UserError) {
        error.value = err.errors[0].message
      }
    })
    .finally(() => {
      loading.value = false
    })
})

const { printPage } = usePrintMode()
const { copyToClipboard } = useCopyToClipboard()

const footerActionOptions = computed(() => ({
  actionLabel: error.value
    ? __('Retry')
    : __("OK, I've saved my recovery codes"),
  actionButton: { variant: 'primary' },
  hideActionButton: loading.value,
  hideCancelButton: true,
}))

const executeAction = async () => {
  if (!props.options?.recoveryCodes) props.successCallback?.()
  return Promise.resolve({})
}

defineExpose({
  executeAction,
  headerSubtitle,
  headerIcon,
  footerActionOptions,
})
</script>

<template>
  <div class="flex flex-col gap-3">
    <template v-if="recoveryCodes">
      <div class="print-area flex flex-col gap-3" data-test-id="print-area">
        <CommonLabel>{{
          $t(
            'Please save your recovery codes listed below somewhere safe. You can use them to sign in if you lose access to another two-factor method:',
          )
        }}</CommonLabel>
        <div
          class="flex flex-wrap gap-5 rounded-lg bg-blue-200 p-5 font-mono text-sm text-gray-100 dark:bg-gray-700 dark:text-neutral-400"
          data-test-id="recovery-codes"
        >
          <div
            v-for="recoveryCode in recoveryCodes"
            :key="recoveryCode"
            class="grow"
          >
            {{ recoveryCode }}
          </div>
        </div>
      </div>
      <div class="mb-1 flex justify-end gap-3">
        <CommonButton
          prefix-icon="printer"
          size="medium"
          @click.prevent="printPage()"
          >{{ $t('Print Codes') }}</CommonButton
        >
        <CommonButton
          prefix-icon="files"
          size="medium"
          @click="copyToClipboard(recoveryCodes?.join('\n'))"
          >{{ $t('Copy Codes') }}</CommonButton
        >
      </div>
    </template>
    <template v-else>
      <CommonLabel class="mx-auto my-3">{{
        $t('Generating recovery codes…')
      }}</CommonLabel>
      <CommonLoader class="my-3" :loading="loading" :error="error" />
    </template>
  </div>
</template>
