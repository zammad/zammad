<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts" generic="T">
import { computed, defineAsyncComponent, type AsyncComponentLoader } from 'vue'

import CommonBadge from '#shared/components/CommonBadge/CommonBadge.vue'
import type { Sizes } from '#shared/components/CommonLabel/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import type { Orientation } from '#desktop/components/CommonPopover/types.ts'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import CommonShowMoreButton from '#desktop/components/CommonShowMoreButton/CommonShowMoreButton.vue'
import entityModules from '#desktop/components/CommonSimpleEntityList/plugins/index.ts'
import { type Entity, EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'

interface Props {
  id: string
  entity: Entity<ObjectLike>
  type: EntityType
  label?: string
  labelSize?: Sizes
  labelClass?: string
  labelTag?: 'span' | 'p' | 'h2' | 'h3' | 'div'
  listClass?: string
  hasPopover?: boolean
  popoverOrientation?: Orientation
  noCollapse?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  labelClass: 'text-current!',
  labelTag: 'h3',
})

const modelValue = defineModel<boolean>({
  default: false,
})

defineEmits<{
  'load-more': []
}>()

const entitySetup = computed(() => {
  const { component: componentAsync, ...context } = entityModules[props.type]

  if (props.hasPopover) {
    context.hasPopover = true

    if (props.popoverOrientation) context.popoverOrientation = props.popoverOrientation
  }

  return {
    component: defineAsyncComponent(componentAsync as AsyncComponentLoader),
    context,
  }
})
</script>

<template>
  <CommonSectionCollapse
    :id="id"
    v-model="modelValue"
    :title="label"
    :no-header="!label"
    :no-collapse="noCollapse"
    container-class="flex flex-col gap-1.5"
  >
    <template #title="{ title, size }">
      <CommonLabel
        class="grow"
        :class="[
          labelClass,
          {
            'select-none': !noCollapse,
          },
        ]"
        :size="labelSize ?? size"
        :tag="labelTag"
        :aria-label="$t(title)"
      >
        {{ $t(title) }}
        <CommonBadge class="leading-snug font-bold ltr:ml-1.5 rtl:mr-1.5" size="xs" rounded>
          {{ entity.totalCount }}
        </CommonBadge>
      </CommonLabel>
    </template>
    <ul v-if="entity.array?.length" class="flex flex-col gap-1.5" :class="listClass">
      <li v-for="item in entity.array" :key="`entity-${item.id}`">
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
