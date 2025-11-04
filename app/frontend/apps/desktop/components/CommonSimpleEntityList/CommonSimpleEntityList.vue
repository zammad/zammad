<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts" generic="T">
import { computed, defineAsyncComponent, type AsyncComponentLoader } from 'vue'

import type { ObjectLike } from '#shared/types/utils.ts'

import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import CommonShowMoreButton from '#desktop/components/CommonShowMoreButton/CommonShowMoreButton.vue'
import entityModules from '#desktop/components/CommonSimpleEntityList/plugins/index.ts'
import { type Entity, EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'

interface Props {
  id: string
  entity: Entity<ObjectLike>
  type: EntityType
  label?: string
  hasPopover?: boolean
}

const props = defineProps<Props>()

const modelValue = defineModel<boolean>({
  default: false,
})

defineEmits<{
  'load-more': []
}>()

const entitySetup = computed(() => {
  const { component: componentAsync, ...context } = entityModules[props.type]

  if (props.hasPopover) context.hasPopover = true

  return {
    component: defineAsyncComponent(componentAsync as AsyncComponentLoader),
    context,
    array: props.entity.array,
  }
})
</script>

<template>
  <CommonSectionCollapse
    :id="id"
    v-model="modelValue"
    :title="label"
    :no-header="!label"
    container-class="flex flex-col gap-1.5"
  >
    <ul v-if="entity.array?.length" class="flex flex-col gap-1.5">
      <li v-for="item in entitySetup.array" :key="`entity-${item.id}`">
        <component :is="entitySetup.component" :entity="item" :context="entitySetup.context" />
      </li>
    </ul>

    <CommonLabel v-if="!entity.array?.length" class="block"
      >{{ entitySetup.context.emptyMessage }}
    </CommonLabel>

    <slot v-if="entity" name="trailing" :total-count="entity.totalCount" :entities="entity.array">
      <CommonShowMoreButton
        class="self-end"
        :entities="entity.array"
        :total-count="entity.totalCount"
        @click="$emit('load-more')"
      />
    </slot>
  </CommonSectionCollapse>
</template>
