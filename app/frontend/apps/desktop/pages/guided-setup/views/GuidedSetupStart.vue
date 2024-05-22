<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'

import {
  EnumSystemSetupInfoStatus,
  EnumSystemSetupInfoType,
} from '#shared/graphql/types.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import LayoutPublicPage from '#desktop/components/layout/LayoutPublicPage/LayoutPublicPage.vue'

import { useSystemSetupLockMutation } from '../graphql/mutations/systemSetupLock.api.ts'
import { systemSetupBeforeRouteEnterGuard } from '../router/guards/systemSetupBeforeRouteEnterGuard.ts'
import { useSystemSetupInfoStore } from '../stores/systemSetupInfo.ts'

defineOptions({
  beforeRouteEnter: systemSetupBeforeRouteEnterGuard,
})

const router = useRouter()

const systemSetupInfoStore = useSystemSetupInfoStore()

const startSetup = (type: EnumSystemSetupInfoType) => {
  const lockMutation = new MutationHandler(useSystemSetupLockMutation())

  lockMutation
    .send()
    .then((data) => {
      systemSetupInfoStore.systemSetupInfo = {
        lockValue: data?.systemSetupLock?.value || '',
        type,
        status: EnumSystemSetupInfoStatus.InProgress,
      }

      router.push(`/guided-setup/${type}`)
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
      <div class="mb-14 mt-10 text-center">
        <CommonButton
          type="submit"
          variant="primary"
          size="large"
          @click="startSetup(EnumSystemSetupInfoType.Manual)"
        >
          {{ $t('Set up a new system') }}
        </CommonButton>
      </div>

      <div class="text-center">
        <CommonButton
          type="submit"
          variant="secondary"
          size="large"
          @click="startSetup(EnumSystemSetupInfoType.Import)"
        >
          {{ $t('Or migrate from another system') }}
        </CommonButton>
      </div>
    </template>
  </LayoutPublicPage>
</template>
