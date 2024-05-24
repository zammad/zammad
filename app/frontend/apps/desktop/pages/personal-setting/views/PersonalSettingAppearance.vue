<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'

import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useThemeStore } from '#desktop/stores/theme.ts'

import { useBreadcrumb } from '../composables/useBreadcrumb.ts'

const { notify } = useNotifications()
const themeStore = useThemeStore()
const { updateTheme } = themeStore
const { currentTheme, savingTheme } = storeToRefs(themeStore)

const modelTheme = computed({
  get: () => currentTheme.value,
  set: (theme) => {
    updateTheme(theme).then(() => {
      notify({
        id: 'theme-update',
        message: __('Your theme has been updated.'),
        type: NotificationTypes.Success,
      })
    })
  },
})

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
        v-model="modelTheme"
        type="radioList"
        name="theme"
        :label="__('Theme')"
        :options="themeOptions"
        :disabled="savingTheme"
      />
    </div>
  </LayoutContent>
</template>
