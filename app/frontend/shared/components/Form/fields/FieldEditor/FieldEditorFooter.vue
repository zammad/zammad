<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ConfidentTake } from '@shared/types/utils'
import { computed } from 'vue'
import type { FieldEditorProps } from './types'

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
</script>

<template>
  <div class="flex" data-test-id="editor-footer">
    <span class="flex-1 ltr:pr-2 rtl:pl-2">{{ footer.text }}</span>
    <span
      v-if="footer.maxlength != null"
      title="Available characters"
      class="text-right"
      :class="{
        'text-red': availableCharactersCount < 0,
        'text-orange':
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
      {{
        $t(
          'You have exceeded the character limit by %s',
          0 - availableCharactersCount,
        )
      }}
    </span>
  </div>
</template>
