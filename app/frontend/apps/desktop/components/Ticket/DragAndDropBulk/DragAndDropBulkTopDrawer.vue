<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import type { Macro } from '#shared/graphql/types.ts'

import BulkAvatarSkeleton from './components/BulkAvatarSkeleton.vue'
import BulkEntityCard from './components/BulkEntityCard.vue'
import BulkScrollList from './components/BulkScrollList.vue'
import { DragAndDropBulkEntityType } from './types.ts'

const props = defineProps<{
  isActive: boolean
  macrosLoaded: boolean
  macros?: Pick<Macro, 'internalId' | 'name'>[]
  dropSuccessTargetId?: number | null
}>()

const list = computed(() =>
  props.macros?.map((macro) => ({
    internalId: macro.internalId,
    label: macro.name,
    type: DragAndDropBulkEntityType.Macro,
  })),
)

const scrollPosition = ref(0)
</script>

<template>
  <header class="w-full">
    <BulkAvatarSkeleton v-if="!macrosLoaded" />

    <transition v-else mode="out-in" name="fade-down">
      <div
        v-if="!isActive && macros?.length"
        class="flex h-52 w-full items-center justify-center py-3"
      >
        <BulkEntityCard
          circle
          :entity-type="DragAndDropBulkEntityType.Macro"
          :label="$t('Run macro')"
        />
      </div>

      <div
        v-else-if="macros?.length"
        class="relative isolate grid w-full grid-rows-[repeat(2,auto)] justify-center gap-3 bg-blue-200 dark:bg-gray-500"
      >
        <BulkScrollList
          ref="scroll-list"
          v-model:scroll-position="scrollPosition"
          :list="list"
          :drop-success-target-id="dropSuccessTargetId"
        />

        <CommonLabel class="row-start-2 block! pb-3 text-center" tag="h3">{{
          $t('Run macro')
        }}</CommonLabel>
      </div>

      <div v-else class="z-53 flex h-48 w-full items-center justify-center">
        <CommonLabel tag="p" class="text-white!">{{
          $t('No macros available for selected tickets')
        }}</CommonLabel>
      </div>
    </transition>
  </header>
</template>
