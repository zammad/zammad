<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { FieldEditorProps } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { useAppName } from '#shared/composables/useAppName.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

interface Props {
  footer: ConfidentTake<FieldEditorProps, 'meta.footer'>
  characters: number
}

const props = defineProps<Props>()

const availableCharactersCount = computed(() => {
  const { maxlength } = props.footer
  if (!maxlength) return 0
  return maxlength - props.characters
})

const appName = useAppName()

const isDesktop = appName === 'desktop'

const characterClassError = isDesktop ? 'text-red-500' : 'text-red'
const characterClassWarning = isDesktop ? 'text-yellow-600' : 'text-orange'
</script>

<template>
  <div class="flex" data-test-id="editor-footer">
    <span class="flex-1 ltr:pr-2 rtl:pl-2">{{ footer.text }}</span>
    <span
      v-if="footer.maxlength != null"
      title="Available characters"
      class="text-right"
      :class="{
        [characterClassError]: availableCharactersCount < 0,
        [characterClassWarning]:
          footer.warningLength &&
          availableCharactersCount >= 0 &&
          availableCharactersCount < footer.warningLength,
      }"
    >
      {{ availableCharactersCount }}
    </span>
    <span
      v-if="footer.maxlength != null && availableCharactersCount < 0"
      class="sr-only"
      aria-atomic="true"
      aria-live="polite"
    >
      {{ $t('You have exceeded the character limit by %s', 0 - availableCharactersCount) }}
    </span>
  </div>
</template>
