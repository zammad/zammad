<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKit } from '@formkit/vue'

import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useNewBetaUi } from '#desktop/composables/useNewBetaUi.ts'

import { useBreadcrumb } from '../composables/useBreadcrumb.ts'

const { breadcrumbItems } = useBreadcrumb(__('New BETA UI'))

const { toggleBetaUiSwitch, toggleDismissBetaUiSwitch, dismissValue } =
  useNewBetaUi()
</script>

<template>
  <LayoutContent :breadcrumb-items="breadcrumbItems" width="full">
    <div class="mb-2 flex flex-col gap-4">
      <FormKit
        type="toggle"
        :label="__('Display Zammad with the New BETA User Interface')"
        :value="true"
        :variants="{ true: 'True', false: 'False' }"
        @input-raw="toggleBetaUiSwitch()"
      />
      <FormKit
        type="checkbox"
        :model-value="!dismissValue"
        :label="
          __(
            'Have the BETA switch between the old and the new UI always available in the Primary Navigation',
          )
        "
        :aria-label="
          dismissValue
            ? $t('Disable the banner for the BETA switch')
            : $t('Enable the banner for the BETA switch')
        "
        name="toggle-dismiss-beta-ui-switch"
        @click="toggleDismissBetaUiSwitch"
      />
    </div>
  </LayoutContent>
</template>
