<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'

import { useBreadcrumb } from '../composables/useBreadcrumb.ts'
import { useThemeUpdate } from '../composables/useThemeUpdate.ts'

const { currentTheme, savingTheme } = useThemeUpdate(true)

const themeOptions = [
  {
    value: 'dark',
    label: __('Dark'),
    description: __(
      'A color scheme that uses light-colored elements on a dark background.',
    ),
  },
  {
    value: 'light',
    label: __('Light'),
    description: __(
      'A color scheme that uses dark-colored elements on a light background.',
    ),
  },
  {
    value: 'auto',
    label: __('Sync with computer'),
    description: __(
      'Prefer color scheme as indicated by the operating system.',
    ),
  },
]

const { breadcrumbItems } = useBreadcrumb(__('Appearance'))
</script>

<template>
  <LayoutContent :breadcrumb-items="breadcrumbItems" width="narrow">
    <div class="mb-4">
      <FormKit
        v-model="currentTheme"
        type="radioList"
        name="theme"
        :label="__('Theme')"
        :options="themeOptions"
        :disabled="savingTheme"
      />
    </div>
  </LayoutContent>
</template>
