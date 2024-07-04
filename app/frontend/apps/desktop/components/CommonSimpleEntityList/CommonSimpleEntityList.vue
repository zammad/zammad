<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts" generic="T">
import { computed } from 'vue'

import CommonShowMoreButton from '#desktop/components/CommonShowMoreButton/CommonShowMoreButton.vue'
import entityModules from '#desktop/components/CommonSimpleEntityList/plugins/index.ts'
import {
  type Entity,
  EntityType,
} from '#desktop/components/CommonSimpleEntityList/types.ts'

interface Props {
  /**
   * Populate entity through `normalizesEdges` function
   * @type {T[]} -> ReturnType of `normalizesEdges` function
   * */
  entity: Entity<T>
  type: EntityType
  label?: string
}

const props = defineProps<Props>()

defineEmits<{
  'load-more': []
}>()

const entitySetup = computed(() => {
  const { component, ...context } = entityModules[props.type]
  return {
    component,
    context,
    data: props.entity.array,
  }
})
</script>

<template>
  <div class="flex flex-col gap-1.5">
    <CommonLabel
      v-if="label"
      class="-:inline-flex items-center text-xs leading-snug text-stone-200 dark:text-neutral-500"
    >
      {{ label }}
    </CommonLabel>

    <TransitionGroup
      v-if="entity.array?.length"
      tag="ul"
      name="fade"
      class="flex flex-col gap-1.5"
    >
      <li
        v-for="(entityValue, index) in entitySetup.data"
        :key="`entity-${index}`"
      >
        <component
          :is="entitySetup.component"
          :entity="entityValue"
          :context="entitySetup.context"
        />
      </li>
    </TransitionGroup>

    <CommonLabel v-if="!entity.array?.length" class="block"
      >{{ entitySetup.context.emptyMessage }}
    </CommonLabel>

    <CommonShowMoreButton
      v-if="entity"
      class="self-end"
      :entities="entity.array"
      :total-count="entity.totalCount"
      @click="$emit('load-more')"
    />
  </div>
</template>
