<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'

import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import {
  EnumSystemSetupInfoStatus,
  EnumSystemSetupInfoType,
} from '#shared/graphql/types.ts'
import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'

import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPage.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useSystemSetupLockMutation } from '../graphql/mutations/systemSetupLock.api.ts'

import { useSystemSetupInfoStore } from '../stores/systemSetupInfo.ts'

const router = useRouter()

const systemSetupInfoStore = useSystemSetupInfoStore()

const startSetup = (mode: string) => {
  const lockMutation = new MutationHandler(useSystemSetupLockMutation())

  lockMutation
    .send()
    .then((data) => {
      systemSetupInfoStore.systemSetupInfo = {
        lockValue: data?.systemSetupLock?.value || '',
        type: mode as EnumSystemSetupInfoType,
        status: EnumSystemSetupInfoStatus.InProgress,
      }

      router.push(`/guided-setup/${mode}`)
    })
    .catch(() => {})
}
</script>

<template>
  <LayoutPublicPage box-size="medium" :title="__('Welcome!')" show-logo>
    <CommonAlert
      v-if="systemSetupInfoStore.systemSetupAlreadyStarted"
      variant="warning"
      >{{
        $t(
          'The setup has already been started. Please wait until it is finished.',
        )
      }}</CommonAlert
    >

    <template v-if="!systemSetupInfoStore.systemSetupAlreadyStarted">
      <div class="text-center mb-14 mt-10">
        <CommonButton
          type="submit"
          variant="primary"
          size="large"
          @click="startSetup('manual')"
        >
          {{ $t('Set up a new system') }}
        </CommonButton>
      </div>

      <div class="text-center">
        <CommonButton
          type="submit"
          variant="secondary"
          size="large"
          @click="startSetup('import')"
        >
          {{ $t('Or migrate from another system') }}
        </CommonButton>
      </div>
    </template>
  </LayoutPublicPage>
</template>
