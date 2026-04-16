<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useElementHover, whenever } from '@vueuse/core'
import { computed, useTemplateRef } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type { AvatarUser } from '#shared/components/CommonUserAvatar/types.ts'

import { DragAndDropBulkEntityType } from '../types.ts'

export interface Props {
  label: string
  entity?: AvatarUser
  entityType: DragAndDropBulkEntityType
  parentLabel?: string
  circle?: boolean
  entityInternalId?: number
  dropSuccessActive?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'go-inside-group': [number]
}>()

const isOwner = computed(() => props.entityType === DragAndDropBulkEntityType.Owner)
const isGroup = computed(() => props.entityType === DragAndDropBulkEntityType.Group)
const isMacro = computed(() => props.entityType === DragAndDropBulkEntityType.Macro)

const avatarEntity = computed(() => (props.entity && isOwner.value ? props.entity : null))
const showInsideGroupAction = computed(() => !props.circle && isGroup.value)

const rootClass = computed(() => [
  'flex flex-col',
  props.circle
    ? 'size-40 items-center justify-center rounded-full border-2 border-dashed border-stone-200 bg-blue-200 dark:border-neutral-500 dark:bg-gray-500'
    : 'w-40 rounded-lg',
  { 'h-full': showInsideGroupAction.value },
])

const hoverClass = computed(() =>
  props.circle ? '' : 'hover:border-blue-800 hover:bg-blue-600 hover:dark:bg-blue-900',
)

const figureClass = computed(() => [
  'flex size-full flex-col items-center justify-center gap-2 rounded-lg p-2 transition-scale duration-200',
  hoverClass.value,
  {
    'rounded-b-none border-b-0!': isGroup.value,
    'border-2 border-dashed border-stone-200 dark:border-neutral-500': !props.circle,
    'bg-blue-800! drop-success-scale': props.dropSuccessActive,
    'border-blue-800!': props.dropSuccessActive && !props.circle,
  },
])

// system user is used to unassign owner
const isSystemUser = computed(() => props.entityInternalId === 1 && isOwner.value)

const iconContainerClass = computed(() => {
  if (isMacro.value) return 'bg-yellow-300'
  if (isSystemUser.value)
    return 'rounded-full! border border-stone-200 text-stone-200 dark:border-neutral-500 dark:text-neutral-500'
  if (isGroup.value) return 'bg-green-500'
  return ''
})

const iconName = computed(() => {
  if (isSystemUser.value) return 'person-x'
  if (isGroup.value) return 'people-fill'
  return 'play-circle'
})

const insideGroupElement = useTemplateRef('inside-group')

const isInsideGroupHovered = useElementHover(insideGroupElement, { delayEnter: 200 })

whenever(isInsideGroupHovered, () => {
  if (!props.entityInternalId) return

  emit('go-inside-group', props.entityInternalId)
})
</script>

<template>
  <div :class="rootClass">
    <figure :class="figureClass">
      <!-- We render the this to make sure the cards keep the same size -->
      <CommonLabel
        v-if="!circle"
        v-tooltip="parentLabel"
        size="small"
        class="line-clamp-1! h-4 break-all text-stone-200 dark:text-neutral-500"
        :class="{ 'text-white!': dropSuccessActive }"
        >{{ parentLabel }}
      </CommonLabel>

      <div
        class="flex size-20 items-center justify-center rounded-lg p-2 text-black"
        :class="[iconContainerClass, { 'border-white!': dropSuccessActive }]"
      >
        <CommonUserAvatar v-if="avatarEntity" size="large" :entity="avatarEntity" />
        <CommonIcon v-else :class="{ 'text-white!': dropSuccessActive }" :name="iconName" />
      </div>

      <figcaption :class="{ 'h-10': !circle }">
        <CommonLabel
          v-tooltip="label"
          class="line-clamp-2! text-center break-word"
          :class="{ 'text-white!': dropSuccessActive }"
          >{{ label }}</CommonLabel
        >
      </figcaption>
    </figure>

    <div
      v-if="showInsideGroupAction"
      ref="inside-group"
      v-tooltip="$t('Go inside group')"
      class="relative flex h-20 w-full shrink-0 flex-col items-center border-x-2 border-t-0 border-dashed border-stone-200 px-2 before:w-full before:border-t-2 before:border-dotted before:border-stone-200 dark:border-neutral-500 before:dark:border-neutral-500"
      :class="hoverClass"
    >
      <CommonIcon class="my-auto" name="arrow-down-short" />
    </div>
  </div>
</template>

<style scoped>
@keyframes drop-success-scale-pop {
  0% {
    transform: scale(1);
  }

  45% {
    transform: scale(1.03);
  }

  100% {
    transform: scale(1);
  }
}

.drop-success-scale {
  animation: drop-success-scale-pop 200ms ease-in-out both infinite;
  will-change: transform;
}
</style>
