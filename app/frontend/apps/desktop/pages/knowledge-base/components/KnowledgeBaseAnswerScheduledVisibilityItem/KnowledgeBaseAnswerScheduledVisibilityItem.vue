<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'
import type { EnumKnowledgeBaseSchedulableVisibility } from '#shared/graphql/types.ts'

import { colorFor, metaFor } from './visibilityScheduleMeta.ts'

// One scheduled visibility change, as both surfaces that list them render it: the editor's sidebar
//   section, where a row can also be removed, and the read-only popover on the answer header's
//   badge. Shared so the state colours - and the exception `archived` makes among them - are
//   decided once, in `visibilityScheduleMeta`.
interface Props {
  visibility: EnumKnowledgeBaseSchedulableVisibility
  scheduledAt: string
}

defineProps<Props>()
</script>

<template>
  <li class="group flex items-center gap-1.5 py-2.5">
    <!-- One clock for every state, rather than the state icons the answer list and the taskbar tab
         show - and tinted with the state's colour where it has one, which is what the design has.
         See #colorFor for why `archived` does not get its own. -->
    <CommonLabel class="grow" prefix-icon="clock" :icon-color="colorFor(visibility)">
      <span :class="colorFor(visibility)">
        {{ $t(metaFor(visibility).label) }}
      </span>

      <!-- Relative, like every other date beside it, and what the design shows: "in 2 days". -->
      <CommonDateTime :date-time="scheduledAt" type="relative" />
    </CommonLabel>

    <!-- Whatever the surface puts after the row: the sidebar's remove button, nothing at all in the
         read-only popover. Inside the `li` and its `group`, which is what that button's
         hover-to-reveal keys off. -->
    <slot />
  </li>
</template>
