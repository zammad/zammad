<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts" generic="T">
import { computed } from 'vue'

import type { ObjectLike } from '#shared/types/utils.ts'

import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import CommonShowMoreButton from '#desktop/components/CommonShowMoreButton/CommonShowMoreButton.vue'
import entityModules from '#desktop/components/CommonSimpleEntityList/plugins/index.ts'
import {
  type Entity,
  EntityType,
} from '#desktop/components/CommonSimpleEntityList/types.ts'

interface Props {
  id: string
  entity: Entity<ObjectLike>
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
    array: props.entity.array,
  }
})
</script>

<template>
  <CommonSectionCollapse :id="id" :title="label" :no-header="!label">
    <ul v-if="entity.array?.length" class="flex flex-col gap-1.5">
      <li v-for="item in entitySetup.array" :key="`entity-${item.id}`">
        <component
          :is="entitySetup.component"
          :entity="item"
          :context="entitySetup.context"
        />
      </li>
    </ul>

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
  </CommonSectionCollapse>
</template>
