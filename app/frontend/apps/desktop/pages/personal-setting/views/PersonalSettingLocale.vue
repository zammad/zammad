<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useLocaleUpdate } from '#shared/composables/useLocaleUpdate.ts'

import LayoutContent from '#desktop/components/layout/LayoutContent.vue'

import { useBreadcrumb } from '../composables/useBreadcrumb.ts'
import { usePersonalSettingTabs } from '../composables/usePersonalSettingTabs.ts'

const { modelCurrentLocale, localeOptions, isSavingLocale, translation } = useLocaleUpdate()

const { breadcrumbItems } = useBreadcrumb(__('Language'))

const { tabs, activeTab } = usePersonalSettingTabs()
</script>

<template>
  <LayoutContent
    :active-tab="activeTab"
    :tabs="tabs"
    :breadcrumb-items="breadcrumbItems"
    width="narrow"
    provide-default
  >
    <div class="mb-4">
      <FormKit
        v-model="modelCurrentLocale"
        type="select"
        name="locale"
        :clearable="false"
        :label="$t('Your language')"
        :disabled="isSavingLocale"
        :no-options-label-translation="true"
        sorting="value"
        :options="localeOptions"
      />

      <p class="mt-4 text-sm">
        {{ $t('Did you know?') }}
        <CommonLink :link="translation.link" size="medium" open-in-new-tab>
          {{ $t('You can help translating Zammad.') }}
        </CommonLink>
      </p>
    </div>
  </LayoutContent>
</template>
