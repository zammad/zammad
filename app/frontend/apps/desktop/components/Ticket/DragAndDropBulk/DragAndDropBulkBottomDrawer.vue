<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTimeoutFn } from '@vueuse/core'
import { isEqual } from 'lodash-es'
import { computed, ref, shallowRef, watch } from 'vue'

import { useFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.api.ts'
import {
  EnumFormUpdaterId,
  type FormUpdaterMetaInput,
  type FormUpdaterQueryVariables,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import type { Props as ParentProps } from '#desktop/components/Ticket/DragAndDropBulk/DragAndDropBulkWrapper.vue'
import { useTicketBulkEdit } from '#desktop/components/Ticket/TicketBulkEditFlyout/useTicketBulkEdit.ts'
import { useTransitionConfig } from '#desktop/composables/useTransitionConfig.ts'

import BulkAvatarSkeleton from './components/BulkAvatarSkeleton.vue'
import BulkEntityCard from './components/BulkEntityCard.vue'
import BulkScrollList from './components/BulkScrollList.vue'
import { DragAndDropBulkEntityType, type BulkScrollListItem, type UserOption } from './types.ts'
import { useGroupWithFlatSelectOptions } from './useGroupWithFlatSelectOptions.ts'

type Props = { isActive: boolean } & Pick<ParentProps, 'dropSuccessTargetEntity'>

const props = defineProps<Props>()

const { bulkSelector } = useTicketBulkEdit()

const selectedGroupInternalId = shallowRef<number | null>(null)
const selectedGroupLabel = shallowRef<string | null>(null)
const isInsideGroup = shallowRef(false)

// Grace period defined first so the exit-delay callback can close over it.
// Prevents the exit bar from triggering immediately after entering a group.
const {
  start: startEnterGrace,
  stop: stopEnterGrace,
  isPending: isInEnterGrace,
} = useTimeoutFn(() => {}, 700, { immediate: false })

const resetGroupState = () => {
  isInsideGroup.value = false
  selectedGroupInternalId.value = null
  selectedGroupLabel.value = null
}

// (mouseleave never fires), so `whenever` stops re-triggering on repeated
const { start: startExitDelay, stop: stopExitDelay } = useTimeoutFn(
  () => {
    if (isInEnterGrace.value) return
    resetGroupState()
  },
  300,
  { immediate: false },
)

const onExitBarEnter = () => {
  stopExitDelay()
  startExitDelay()
}

const onExitBarLeave = () => stopExitDelay()

// When the drawer stops being active (user moved away), reset group state after
// a short delay so a brief cursor exit does not lose the user's position.
const { start: startLeaveTimer, stop: stopLeaveTimer } = useTimeoutFn(resetGroupState, 600, {
  immediate: false,
})

watch(
  () => props.isActive,
  (active) => {
    if (!active && isInsideGroup.value) {
      startLeaveTimer()
    } else {
      stopLeaveTimer()
    }
  },
)

const queryVariables = computed<FormUpdaterQueryVariables>(() => {
  const meta: FormUpdaterMetaInput = {
    additionalData: {
      ...bulkSelector.value,
      enrichOwnerOptions: true,
    },
    requestId: 'tickets-bulk-edit-drag-and-drop-request',
    formId: 'tickets-bulk-edit-drag-and-drop',
  }

  return selectedGroupInternalId.value
    ? {
        formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterTicketBulkEdit,
        meta,
        data: { group_id: selectedGroupInternalId.value },
        relationFields: [
          { name: 'group_id', relation: 'Group' },
          { name: 'owner_id', relation: 'User' },
        ],
      }
    : {
        formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterTicketBulkEdit,
        meta,
        data: {},
        relationFields: [
          { name: 'group_id', relation: 'Group' },
          { name: 'owner_id', relation: 'User' },
        ],
      }
})

const queryHandler = new QueryHandler(useFormUpdaterQuery(queryVariables))

const isLoading = queryHandler.loadingWithoutCachedResult()

const result = queryHandler.result()

const groupOptions = computed(() => result.value?.formUpdater.fields.group_id.options ?? null)

const ownerList = computed<UserOption[] | null>(
  () => result.value?.formUpdater.fields.owner_id.options ?? null,
)

const {
  flatOptions,
  getSelectedOptionLabel,
  getSelectedOptionFullPath,
  getSelectedOptionParentsPath,
} = useGroupWithFlatSelectOptions(groupOptions)

const topLevelList = computed<BulkScrollListItem[]>((currentList) => {
  const list: BulkScrollListItem[] = []

  list.push({
    internalId: 1,
    label: i18n.t('Unassign owner'),
    type: DragAndDropBulkEntityType.Owner,
  })

  if (ownerList.value?.length)
    list.push(
      ...ownerList.value.map((option) => ({
        internalId: option.value,
        label: option.label,
        type: DragAndDropBulkEntityType.Owner,
        object: option.object,
      })),
    )

  if (flatOptions.value?.length)
    list.push(
      ...flatOptions.value.map((option) => ({
        internalId: option.value as number,
        label: getSelectedOptionLabel(option.value) as string,
        parentLabel: getSelectedOptionParentsPath(option.value as number),
        type: DragAndDropBulkEntityType.Group,
      })),
    )

  return currentList && isEqual(currentList, list) ? currentList : list
})

const groupMembers = computed<BulkScrollListItem[]>((currentList) => {
  const list: BulkScrollListItem[] = []

  list.push({
    internalId: 1,
    groupInternalId: selectedGroupInternalId.value!,
    label: i18n.t('Unassign owner & move to group'),
    type: DragAndDropBulkEntityType.Owner,
  })

  list.push(
    ...result.value?.formUpdater.fields.owner_id.options.map((option: UserOption) => ({
      internalId: option.value,
      groupInternalId: selectedGroupInternalId.value!,
      label: option.label,
      type: DragAndDropBulkEntityType.Owner,
      object: option.object,
    })),
  )

  return currentList && isEqual(currentList, list) ? currentList : list
})

const goInsideGroup = (internalId: number) => {
  stopExitDelay()
  isInsideGroup.value = true
  selectedGroupInternalId.value = internalId
  selectedGroupLabel.value = getSelectedOptionFullPath(internalId)
  stopEnterGrace()
  startEnterGrace()
}

const scrollPosition = ref(0)

const { transitions } = useTransitionConfig()
</script>

<template>
  <footer class="w-full" :class="{ 'h-74': isActive }">
    <BulkAvatarSkeleton v-if="isLoading && !result?.formUpdater" />

    <Transition v-else :name="transitions.fadeUp" mode="out-in">
      <div
        v-if="!isActive && groupOptions?.length"
        class="flex h-52 w-full items-center justify-center py-3"
      >
        <BulkEntityCard
          circle
          :entity-type="DragAndDropBulkEntityType.Group"
          :label="$t('Assign tickets')"
        />
      </div>

      <div v-else class="relative isolate w-full overflow-y-clip bg-blue-200 dark:bg-gray-500">
        <Transition :name="transitions.fadeDown" mode="out-in">
          <div
            v-if="isInsideGroup"
            class="grid w-full grid-rows-[repeat(2,auto)] justify-stretch gap-3 px-3"
          >
            <button
              v-tooltip="$t('Go back')"
              type="button"
              class="flex h-14 w-full cursor-pointer items-center justify-center rounded-b-lg border-2 border-t-0 border-dashed border-stone-200 focus-visible-app-default hover:bg-blue-600 focus:outline-none dark:border-neutral-500 hover:dark:bg-blue-900"
              @mouseenter="onExitBarEnter"
              @mouseleave="onExitBarLeave"
              @focus="onExitBarEnter"
              @blur="onExitBarLeave"
            >
              <CommonIcon name="arrow-up-short" />
            </button>

            <BulkScrollList
              class="flex justify-center"
              :list="groupMembers"
              :drop-success-target-entity="dropSuccessTargetEntity"
            />

            <CommonLabel class="row-start-3 block! pb-6 text-center" tag="h3">{{
              selectedGroupLabel
            }}</CommonLabel>
          </div>

          <div v-else class="grid w-full grid-rows-[repeat(2,auto)] justify-stretch gap-3">
            <CommonLabel class="row-start-1 block! pt-3 text-center" tag="h3">{{
              $t('Assign tickets')
            }}</CommonLabel>

            <BulkScrollList
              v-model:scroll-position="scrollPosition"
              class="flex justify-center"
              :list="topLevelList"
              :drop-success-target-entity="dropSuccessTargetEntity"
              @go-inside-group="goInsideGroup"
            />
          </div>
        </Transition>
      </div>
    </Transition>
  </footer>
</template>
