<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { getKeyboardShortcutPlatform } from '#shared/composables/useKeyboardShortcut/keyboardShortcutCatalogue.ts'
import type { KeyboardShortcutGroup } from '#shared/composables/useKeyboardShortcut/types.ts'
import { markup } from '#shared/utils/markup.ts'

import KeyboardShortcutsDialogKey from './KeyboardShortcutsDialogKey.vue'

defineProps<{
  group: KeyboardShortcutGroup
}>()

const platform = getKeyboardShortcutPlatform()
</script>

<template>
  <section class="flex flex-col gap-3" :aria-labelledby="`keyboard-shortcuts-${group.key}`">
    <h4 :id="`keyboard-shortcuts-${group.key}`" class="text-xl/snug text-normal">
      {{ $t(group.headline) }}
    </h4>
    <div v-for="subGroup in group.subGroups" :key="subGroup.key" class="flex flex-col gap-3">
      <CommonLabel :id="`keyboard-shortcuts-${group.key}-${subGroup.key}`" class="text-muted!">
        {{ $t(subGroup.where) }}
      </CommonLabel>
      <ul
        class="flex flex-col gap-1.5"
        :aria-labelledby="`keyboard-shortcuts-${group.key}-${subGroup.key}`"
      >
        <li v-for="entry in subGroup.entries" :key="entry.key" class="flex items-center gap-1.5">
          <span class="flex shrink-0 items-center gap-1">
            <template v-for="(step, stepIndex) in entry.displayKeys[platform]" :key="stepIndex">
              <CommonLabel v-if="stepIndex > 0" size="small">{{ $t('then') }}</CommonLabel>
              <KeyboardShortcutsDialogKey
                v-for="displayKey in step"
                :key="displayKey"
                :display-key="displayKey"
              />
            </template>
          </span>
          <CommonLabel class="min-w-0" size="small">
            <!-- eslint-disable-next-line vue/no-v-html -->
            <span v-html="markup($t(entry.description))" />
          </CommonLabel>
        </li>
      </ul>
    </div>
  </section>
</template>
