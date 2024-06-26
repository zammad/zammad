<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'

import { EnumSystemImportSource } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'

import GuidedSetupActionFooter from '#desktop/pages/guided-setup/components/GuidedSetupActionFooter.vue'
import { guidedSetupImportSourcePluginLookup } from '#desktop/pages/guided-setup/components/GuidedSetupImport/GuidedSetupImportSource/plugins/index.ts'
import GuidedSetupStatusMessage from '#desktop/pages/guided-setup/components/GuidedSetupStatusMessage.vue'
import { useImportSource } from '#desktop/pages/guided-setup/composables/useImportSource.ts'
import { useSystemSetup } from '#desktop/pages/guided-setup/composables/useSystemSetup.ts'
import { useSystemSetupInfoStore } from '#desktop/pages/guided-setup/stores/systemSetupInfo.ts'

interface Props {
  source: EnumSystemImportSource
}

const props = defineProps<Props>()

const sourcePlugin = guidedSetupImportSourcePluginLookup[props.source]
const { setTitle } = useSystemSetup()

setTitle(i18n.t('Import from %s', sourcePlugin.label))

const router = useRouter()

const systemSetupInfoStore = useSystemSetupInfoStore()

const goBack = () => {
  systemSetupInfoStore.systemSetupInfo.importSource = undefined

  router.push('/guided-setup/import')
}

const { form, debouncedLoading, onContinueButtonCallback } = useImportSource()
// TODO: :on-submit="onContinueButtonCallback" is a workaround for the issue that inside the test the change of the such
// a event handler is not triggered. Create small reproduction repo and open issue in vue-test-utils.
</script>

<template>
  <GuidedSetupStatusMessage
    v-if="debouncedLoading"
    :message="__('Verifying and saving your import configuration…')"
  />
  <div v-show="!debouncedLoading">
    <component :is="sourcePlugin.component" />

    <GuidedSetupActionFooter
      :form="form"
      :submit-button-text="
        onContinueButtonCallback ? __('Continue') : __('Save and Continue')
      "
      :submit-button-type="onContinueButtonCallback ? 'button' : 'submit'"
      :submit-button-variant="onContinueButtonCallback ? 'primary' : 'submit'"
      :on-submit="onContinueButtonCallback"
      @go-back="goBack()"
      @submit="onContinueButtonCallback"
    />
  </div>
</template>
