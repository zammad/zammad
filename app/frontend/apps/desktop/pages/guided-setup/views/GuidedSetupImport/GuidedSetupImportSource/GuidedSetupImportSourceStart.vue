<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'

import { EnumSystemImportSource } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import GuidedSetupActionFooter from '../../../components/GuidedSetupActionFooter.vue'
import { guidedSetupImportSourcePluginLookup } from '../../../components/GuidedSetupImport/GuidedSetupImportSource/plugins/index.ts'
import { useSystemSetup } from '../../../composables/useSystemSetup.ts'
import { useSystemImportStartMutation } from '../../../graphql/mutations/systemImportStart.api.ts'
import { useSystemSetupInfoStore } from '../../../stores/systemSetupInfo.ts'

defineOptions({
  // The import source start page is only available when "import_backend" already exists
  // and the previous route was not the import from source page.
  beforeRouteEnter(to, from) {
    const application = useApplicationStore()

    if (
      !application.config.import_backend &&
      from.name !== 'GuidedSetupImportSource'
    ) {
      return { path: `/guided-setup/import/${to.params.source}`, replace: true }
    }
  },
})

interface Props {
  source: EnumSystemImportSource
}

const props = defineProps<Props>()

const router = useRouter()

const { setTitle } = useSystemSetup()
const { systemSetupUnlock } = useSystemSetupInfoStore()

const sourcePlugin = guidedSetupImportSourcePluginLookup[props.source]

setTitle(i18n.t('Start Import from %s', sourcePlugin.label))

const startImport = () => {
  const importStartMutation = new MutationHandler(
    useSystemImportStartMutation(),
  )

  importStartMutation
    .send()
    .then(() => {
      systemSetupUnlock(() => {
        router.push(`/guided-setup/import/${props.source}/status`)
      })
    })
    .catch(() => {})
}
</script>

<template>
  <div class="mb-2.5 flex flex-col gap-3">
    <CommonLabel
      >{{
        $t(
          'Initiate the import process to transfer your data into Zammad. Keep track of the migration progress on this page to be notified as soon as the import is successfully finished.',
        )
      }}
    </CommonLabel>
    <CommonLink
      class="text-sm"
      :link="sourcePlugin.documentationURL"
      external
      open-in-new-tab
      >{{
        $t('For additional support, consult our migration guide.')
      }}</CommonLink
    >
    <div
      v-if="sourcePlugin.preStartHints && sourcePlugin.preStartHints.length > 0"
      class="flex flex-col gap-1.5"
    >
      <CommonLabel>
        {{
          $t(
            'Before you start, make sure to check the following points to ensure a smooth migration and usage of your Zammad instance:',
          )
        }}
      </CommonLabel>

      <ul
        class="flex list-disc flex-col gap-1.5 text-sm text-gray-100 ltr:ml-5 rtl:mr-5 dark:text-neutral-400"
      >
        <li v-for="hint in sourcePlugin.preStartHints" :key="hint">
          {{ $t(hint) }}
        </li>
      </ul>
    </div>
  </div>
  <GuidedSetupActionFooter
    :go-back-route="`/guided-setup/import/${source}`"
    :submit-button-text="__('Start Import')"
    @submit="startImport"
  />
</template>
