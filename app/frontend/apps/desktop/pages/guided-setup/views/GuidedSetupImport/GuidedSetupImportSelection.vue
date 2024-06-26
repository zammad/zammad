<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'

import CommonButtonGroup from '#desktop/components/CommonButtonGroup/CommonButtonGroup.vue'
import type { CommonButtonItem } from '#desktop/components/CommonButtonGroup/types.ts'
import { guidedSetupImportSourcePlugins } from '#desktop/pages/guided-setup/components/GuidedSetupImport/GuidedSetupImportSource/plugins/index.ts'

import GuidedSetupActionFooter from '../../components/GuidedSetupActionFooter.vue'
import { useSystemSetup } from '../../composables/useSystemSetup.ts'
import { useSystemSetupInfoStore } from '../../stores/systemSetupInfo.ts'

const { setTitle } = useSystemSetup()

setTitle(__('Import from'))

const router = useRouter()

const systemSetupInfoStore = useSystemSetupInfoStore()

const startImport = (source: string) => {
  systemSetupInfoStore.systemSetupInfo.importSource = source

  router.push(`/guided-setup/import/${source}`)
}

const importPlugins: CommonButtonItem[] = guidedSetupImportSourcePlugins.map(
  (plugin) => {
    return {
      label: plugin.label,
      variant: 'primary',
      size: 'medium',
      onActionClick: () => startImport(plugin.source),
    }
  },
)

const unlockCallback = () => {
  router.push('/guided-setup')
}
</script>

<template>
  <CommonButtonGroup :items="importPlugins" class="mb-5">
    <template #item="{ label }">
      <span class="ltr:mr-1.5 rtl:ml-1.5">
        {{ $t(label) }}
      </span>
      <CommonBadge
        class="bg-pink-300 text-white dark:bg-pink-300"
        variant="custom"
        >{{ $t('Beta') }}</CommonBadge
      >
    </template>
  </CommonButtonGroup>
  <GuidedSetupActionFooter
    @go-back="systemSetupInfoStore.systemSetupUnlock(unlockCallback)"
  />
</template>
