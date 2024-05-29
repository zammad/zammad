<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useLocaleUpdate } from '#shared/composables/useLocaleUpdate.ts'

import LayoutContent from '#desktop/components/layout/LayoutContent.vue'

import { useBreadcrumb } from '../composables/useBreadcrumb.ts'

const { modelCurrentLocale, localeOptions, isSavingLocale, translation } =
  useLocaleUpdate()

const { breadcrumbItems } = useBreadcrumb(__('Language'))
</script>

<template>
  <LayoutContent
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
        sorting="label"
        :options="localeOptions"
      />

      <p class="mt-4 text-sm">
        {{ $t('Did you know?') }}
        <CommonLink target="_blank" :link="translation.link">
          {{ $t('You can help translating Zammad.') }}
        </CommonLink>
      </p>
    </div>
  </LayoutContent>
</template>
