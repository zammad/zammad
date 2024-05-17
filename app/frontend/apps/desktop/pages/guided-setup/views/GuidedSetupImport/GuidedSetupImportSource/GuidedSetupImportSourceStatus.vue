<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTimeoutFn } from '@vueuse/shared'
import { computed, ref, watch, watchEffect } from 'vue'
import { useRouter } from 'vue-router'

import { EnumSystemImportSource } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonProgressBar from '#desktop/components/CommonProgressBar/CommonProgressBar.vue'

import GuidedSetupActionFooter from '../../../components/GuidedSetupActionFooter.vue'
import { guidedSetupImportSourcePluginLookup } from '../../../components/GuidedSetupImport/GuidedSetupImportSource/plugins/index.ts'
import GuidedSetupStatusMessage from '../../../components/GuidedSetupStatusMessage.vue'
import { useSystemSetup } from '../../../composables/useSystemSetup.ts'
import { useSystemImportStateQuery } from '../../../graphql/queries/systemImportState.api.ts'

import type { ImportSourceStatusProgressItem } from '../../../types/setup-import.ts'

defineOptions({
  // The import source status page is only available when "import_mode" is set.
  beforeRouteEnter(to, from) {
    const application = useApplicationStore()

    if (from.name === 'GuidedSetupImportSourceStart') {
      return true
    }

    if (!application.config.import_mode) {
      return {
        path: `/guided-setup/import/${to.params.source}`,
        replace: true,
      }
    }
  },
})

interface Props {
  source: EnumSystemImportSource
}

const props = defineProps<Props>()

const { setTitle } = useSystemSetup()

const sourcePlugin = guidedSetupImportSourcePluginLookup[props.source]

setTitle(i18n.t('%s Import Status', sourcePlugin.label))

const systemSetupImportStatusQuery = new QueryHandler(
  useSystemImportStateQuery({
    pollInterval: 5000,
  }),
)

const systemSetupImportStatusQueryResult = systemSetupImportStatusQuery.result()

const importIsStarted = computed(() => {
  return Boolean(
    systemSetupImportStatusQueryResult.value?.systemImportState?.startedAt,
  )
})

const importJobIsFinished = computed(() => {
  return Boolean(
    systemSetupImportStatusQueryResult.value?.systemImportState?.finishedAt,
  )
})

const importJobErrorMessage = computed(() => {
  const jobResult =
    systemSetupImportStatusQueryResult.value?.systemImportState?.result

  if (!jobResult || !jobResult.error) return

  return jobResult.error as string
})

const currentSystemSetupImportProgressItems = computed(() => {
  if (!importIsStarted.value) return []

  const stats =
    systemSetupImportStatusQueryResult.value?.systemImportState?.result

  if (!stats) return []

  const progressStats: ImportSourceStatusProgressItem[] = []

  Object.entries(sourcePlugin.importEntities).forEach(([entity, label]) => {
    progressStats.push({
      entity,
      entityLabel: label,
      processed:
        stats[entity] && stats[entity].sum
          ? String(stats[entity].sum)
          : undefined,
      total:
        stats[entity] && stats[entity].total
          ? String(stats[entity].total)
          : undefined,
      isFinished: false,
    })
  })

  progressStats.forEach((item) => {
    if (
      item.processed &&
      item.total &&
      Number(item.processed) > Number(item.total)
    ) {
      item.processed = item.total
    }

    if (
      item.processed !== undefined &&
      item.total !== undefined &&
      item.processed === item.total
    )
      item.isFinished = true
  })

  return progressStats
})

const importJobStartError = ref(false)

const importJobErrorPresent = computed(() => {
  return Boolean(importJobStartError.value || importJobErrorMessage.value)
})

const checkImportJobStartError = useTimeoutFn(
  () => {
    importJobStartError.value = true
    systemSetupImportStatusQuery.stop()
  },
  90000,
  { immediate: false },
)
watch(importIsStarted, (newValue) => {
  if (newValue === true) {
    checkImportJobStartError.stop()
  }
})

// Check if a message was received from the server.
// If this is the case start timeout that will stop the polling after 90 seconds.
watch(importJobErrorMessage, (errorMessage) => {
  if (errorMessage) {
    checkImportJobStartError.start()
  } else {
    checkImportJobStartError.stop()
  }
})

watch(importJobIsFinished, (newValue) => {
  if (newValue === true) {
    systemSetupImportStatusQuery.stop()
  }
})

const systemInitSettingsUpdated = ref(false)
const application = useApplicationStore()

watchEffect(() => {
  if (
    application.config.system_init_done &&
    application.config.import_mode === false
  ) {
    systemInitSettingsUpdated.value = true
  }
})

// Start the timeout to check if the import job has started if needed.
if (!importIsStarted.value) {
  checkImportJobStartError.start()
}

const systemInitDone = computed(() => {
  return (
    systemInitSettingsUpdated.value &&
    importJobIsFinished.value &&
    !importJobErrorMessage.value
  )
})

const router = useRouter()
const goToLogin = () => {
  router.push('/login')
}
</script>

<template>
  <CommonAlert v-if="importJobErrorPresent" variant="danger">
    {{
      $t(
        importJobErrorMessage
          ? importJobErrorMessage
          : 'Background process did not start or has not finished! Please contact your support.',
      )
    }}
  </CommonAlert>

  <GuidedSetupStatusMessage
    v-if="
      !importJobErrorPresent &&
      (!importIsStarted || currentSystemSetupImportProgressItems.length === 0)
    "
    :message="__('Starting import…')"
  />

  <div v-if="importIsStarted" class="mb-5 flex flex-col gap-3">
    <CommonAlert v-if="systemInitDone" variant="success">
      {{ $t('Import finished successfully!') }}
    </CommonAlert>

    <div
      v-for="item in currentSystemSetupImportProgressItems"
      :key="item.entity"
      class="flex items-end gap-2"
    >
      <div class="mb-1 flex grow flex-col gap-1">
        <div class="flex justify-between gap-2">
          <CommonLabel :id="`progress-${item.entity}`">
            {{ $t(item.entityLabel) }}
          </CommonLabel>

          <CommonLabel
            v-if="item.processed !== undefined && item.total !== undefined"
            class="text-stone-200 dark:text-neutral-500"
          >
            {{ $t('%s of %s', item.processed, item.total) }}
          </CommonLabel>
        </div>

        <CommonProgressBar
          :aria-labelledby="`progress-${item.entity}`"
          :value="item.processed"
          :max="item.total"
        />
      </div>

      <CommonIcon
        class="shrink-0 fill-green-500"
        :class="!item.isFinished ? 'invisible' : undefined"
        name="check2"
        size="tiny"
        decorative
      />
    </div>
  </div>

  <GuidedSetupActionFooter
    v-if="systemInitDone"
    submit-button-variant="primary"
    submit-button-type="button"
    :submit-button-text="__('Go to Login')"
    @submit="goToLogin"
  />
</template>
