<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import CommonTicketStateIndicator from '@shared/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import { useEditedBy } from '@mobile/composables/useEditedBy'
import { type TicketItemData } from './types'

export interface Props {
  entity: TicketItemData
}

interface Priority {
  class: string | null
  text: string
}

const props = defineProps<Props>()

const { stringUpdated } = useEditedBy(toRef(props, 'entity'))

// TODO
const priority = computed<Priority | null>(() => {
  const { entity } = props
  if (!entity.priority) {
    return null
  }
  return {
    class: entity.priority.uiColor
      ? `u-${entity.priority.uiColor}-color`
      : `u-default-color`,
    text: entity.priority.name.toUpperCase(),
  }
})
</script>

<template>
  <div class="flex">
    <div class="flex w-12 items-center justify-center">
      <!-- TODO label? -->
      <CommonTicketStateIndicator
        :status="entity.state"
        :label="entity.state"
      />
    </div>
    <div
      class="flex flex-1 items-center border-b border-white/10 py-3 text-gray-100"
    >
      <div class="flex-1">
        <div class="flex">
          <div>#{{ entity.id }}</div>
          <div v-if="entity.owner" class="px-1">·</div>
          <div v-if="entity.owner">
            {{ entity.owner.firstname }} {{ entity.owner.lastname }}
          </div>
        </div>
        <div class="mb-1 text-lg font-bold">
          <slot>
            {{ entity.title }}
          </slot>
        </div>
        <div
          v-if="stringUpdated"
          data-test-id="stringUpdated"
          class="text-gray"
        >
          {{ stringUpdated }}
        </div>
      </div>
      <div
        v-if="priority"
        :class="[priority.class, 'h-min rounded-[4px] py-1 px-2']"
      >
        {{ priority.text }}
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.u-default-color {
  @apply bg-gray/10 text-gray;
}

.u-high-priority-color {
  @apply bg-red/10 text-red;
}

.u-low-priority-color {
  @apply bg-blue/10 text-blue;
}

.u-medium-priority-color {
  @apply bg-yellow/10 text-yellow;
}
</style>
