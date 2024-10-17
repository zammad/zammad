<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script lang="ts" setup>
import { cloneDeep } from 'lodash-es'
import { computed, nextTick, ref, useTemplateRef } from 'vue'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { handleUserErrors } from '#shared/errors/utils.ts'
import type {
  ChecklistItem,
  TicketChecklistItemInput,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import ChecklistEmptyTemplates from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklist/TicketSidebarChecklistContent/ChecklistEmptyTemplates.vue'
import ChecklistItems from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklist/TicketSidebarChecklistContent/ChecklistItems.vue'
import ChecklistTemplates from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklist/TicketSidebarChecklistContent/ChecklistTemplates.vue'
import type { AddNewChecklistInput } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklist/types.ts'
import { useChecklistTemplates } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklist/useChecklistTemplates.ts'
import { useTicketChecklist } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklist/useTicketChecklist.ts'
import TicketSidebarContent from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarContent.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { useTicketNumber } from '#desktop/pages/ticket/composables/useTicketNumber.ts'
import { useTicketChecklistAddMutation } from '#desktop/pages/ticket/graphql/mutations/ticketChecklistAdd.api.ts'
import { useTicketChecklistDeleteMutation } from '#desktop/pages/ticket/graphql/mutations/ticketChecklistDelete.api.ts'
import { useTicketChecklistItemDeleteMutation } from '#desktop/pages/ticket/graphql/mutations/ticketChecklistItemDelete.api.ts'
import { useTicketChecklistItemOrderUpdateMutation } from '#desktop/pages/ticket/graphql/mutations/ticketChecklistItemOrderUpdate.api.ts'
import { useTicketChecklistItemUpsertMutation } from '#desktop/pages/ticket/graphql/mutations/ticketChecklistItemUpsert.api.ts'
import { useTicketChecklistTitleUpdateMutation } from '#desktop/pages/ticket/graphql/mutations/ticketChecklistTitleUpdate.api.ts'
import type { TicketSidebarContentProps } from '#desktop/pages/ticket/types/sidebar.ts'

defineProps<TicketSidebarContentProps>()

const checklistItemsInstance = useTemplateRef('checklist-items')

const { cache: apolloCache } = getApolloClient()
const { ticket, ticketId, isTicketEditable } = useTicketInformation()
const { ticketNumberWithTicketHook } = useTicketNumber(ticket)

const { checklist, isLoadingChecklist } = useTicketChecklist(ticketId, ticket)

const checklistTitle = computed(
  () =>
    checklist.value?.name ||
    i18n.t('%s Checklist', ticketNumberWithTicketHook.value),
)

const addNewChecklistMutation = new MutationHandler(
  useTicketChecklistAddMutation(),
)

const createNewChecklist = async (
  input?: Omit<AddNewChecklistInput, 'ticketId'>,
  options = { focusLastItem: true },
) => {
  if (ticket.value?.id) {
    return addNewChecklistMutation
      .send({
        ...input,
        ticketId: ticket.value.id,
      })
      .then(() => {
        if (options.focusLastItem)
          nextTick(() => checklistItemsInstance.value?.focusNewItem())
      })
      .catch(handleUserErrors)
  }
}

const checklistTitleUpdateMutation = new MutationHandler(
  useTicketChecklistTitleUpdateMutation(),
)

const checklistDeleteMutation = new MutationHandler(
  useTicketChecklistDeleteMutation(),
)

const removeChecklist = async () => {
  const { waitForVariantConfirmation } = useConfirmation()

  const confirmed = await waitForVariantConfirmation('delete')

  if (confirmed)
    await checklistDeleteMutation
      .send({
        checklistId: checklist.value?.id as string,
      })
      .catch(handleUserErrors)
}

const updateTitle = async (title: string) => {
  return checklistTitleUpdateMutation
    .send({
      title,
      checklistId: checklist.value?.id as string,
    })
    .then(() => {})
    .catch(handleUserErrors)
}

const itemAddMutation = new MutationHandler(
  useTicketChecklistItemUpsertMutation({
    update: (cache, { data }) => {
      if (!data || !checklist.value) return

      const { ticketChecklistItemUpsert } = data
      if (!ticketChecklistItemUpsert?.checklistItem) return

      const newIdPresent = checklist.value?.items.find((item) => {
        return item.id === ticketChecklistItemUpsert.checklistItem?.id
      })

      if (newIdPresent) return

      cache.modify({
        id: cache.identify(checklist.value),
        fields: {
          items(currentItems, { toReference }) {
            return [
              ...currentItems,
              toReference(ticketChecklistItemUpsert.checklistItem!),
            ]
          },
          complete(currentComplete) {
            return currentComplete + 1
          },
          total(totalCount) {
            return totalCount + 1
          },
          incomplete(incompleteCount) {
            return incompleteCount + 1
          },
        },
      })
    },
  }),
  {
    errorNotificationMessage: __('Failed to add new checklist item.'),
  },
)

const itemOrderMutation = new MutationHandler(
  useTicketChecklistItemOrderUpdateMutation(),
  {
    errorNotificationMessage: __('Failed to save checklist order.'),
  },
)

const itemUpsertMutation = new MutationHandler(
  useTicketChecklistItemUpsertMutation(),
  {
    errorNotificationMessage: __('Failed to update checklist item.'),
  },
)

const itemDeleteMutation = new MutationHandler(
  useTicketChecklistItemDeleteMutation(),
  {
    errorNotificationMessage: __('Failed to delete checklist item.'),
  },
)

const isUpdatingOrder = itemOrderMutation.loading()
const isAddingNewItem = itemAddMutation.loading()
const isAddingNewChecklist = addNewChecklistMutation.loading()
const isUpdatingChecklistTitle = checklistTitleUpdateMutation.loading()
const updatingItemIds = ref<Set<ID>>(new Set())

const deleteUpdatingItemId = (id: ID) => {
  updatingItemIds.value.delete(id)
}

const addUpdatingItemId = (id: ID) => {
  updatingItemIds.value.add(id)
}

const modifyIncompleteItemCountCache = (increase: boolean) => {
  const currentCheckList = checklist.value!
  const previousIncompleteItemCount = currentCheckList.incomplete
  const previousCompleted = currentCheckList.completed

  let incompleteItemCount = currentCheckList.incomplete ?? 0

  // Update the incomplete item count based on the mutated checked state, not waiting for the subscription to kick in.
  //   The recalculation below does not take into account any ticket checklist items and their state.
  //   Their change will update the incomplete item count via the subscription update after a short delay.
  if (increase) incompleteItemCount += 1
  else incompleteItemCount -= 1

  if (incompleteItemCount < 0 || !currentCheckList.items)
    incompleteItemCount = 0
  else if (incompleteItemCount > currentCheckList.items.length)
    incompleteItemCount = currentCheckList.items.length

  const checklistId = apolloCache.identify(currentCheckList)

  apolloCache.modify({
    id: checklistId,
    fields: {
      incomplete() {
        return incompleteItemCount
      },
      total() {
        return currentCheckList.items.length
      },
      completed() {
        return incompleteItemCount === 0
      },
      complete() {
        return currentCheckList.items.length - incompleteItemCount
      },
    },
  })

  // Return function to restore cache to the previous state.
  return () => {
    apolloCache.modify({
      id: checklistId,
      fields: {
        incomplete() {
          return previousIncompleteItemCount
        },
        completed() {
          return previousCompleted
        },
        total() {
          return currentCheckList.items.length
        },
        complete() {
          return currentCheckList.items.length - previousIncompleteItemCount
        },
      },
    })
  }
}

const modifyCheckedCache = (item: ChecklistItem) => {
  const checklistItemId = apolloCache.identify(item)

  apolloCache.modify({
    id: checklistItemId,
    fields: {
      checked() {
        return item.checked
      },
    },
  })

  const restoreIncompleteItemCountCache = modifyIncompleteItemCountCache(
    !item.checked,
  )

  // Return function to restore cache to the previous state.
  return () => {
    restoreIncompleteItemCountCache()

    apolloCache.modify({
      id: checklistItemId,
      fields: {
        checked() {
          return !item.checked
        },
      },
    })
  }
}

const modifyItemsCache = (items: ChecklistItem[]) => {
  const currentCheckList = checklist.value

  const checklistId = apolloCache.identify(currentCheckList)

  apolloCache.modify({
    id: checklistId,
    fields: {
      items(_, { toReference }) {
        // We need to transform it to a real reference, that we do not lose the connection.
        // Side effect is that data updates on single items are not applied.
        return items.map((item) => toReference(item, true))
      },
    },
  })
}

const updateItem = async (itemId: string, input: TicketChecklistItemInput) => {
  addUpdatingItemId(itemId)

  return itemUpsertMutation
    .send({
      checklistId: checklist.value?.id as string,
      checklistItemId: itemId,
      input,
    })
    .finally(() => {
      deleteUpdatingItemId(itemId)
    })
}

const setItemCheckedState = async (item: ChecklistItem) => {
  const restoreCache = modifyCheckedCache(item)

  addUpdatingItemId(item.id)

  await updateItem(item.id, { checked: item.checked })
    .catch((error) => {
      restoreCache()
      handleUserErrors(error)
    })
    .finally(() => {
      deleteUpdatingItemId(item.id)
    })
}

const addNewItem = async () =>
  itemAddMutation
    .send({
      checklistId: checklist.value?.id as string,
      input: {
        text: '',
        checked: false,
      },
    })
    .then(() => {
      checklistItemsInstance.value?.focusNewItem()
    })
    .catch(handleUserErrors)

const editItem = async (item: ChecklistItem) => {
  addUpdatingItemId(item.id)

  return updateItem(item.id, { text: item.text })
    .then(() => {})
    .catch(handleUserErrors)
    .finally(() => {
      deleteUpdatingItemId(item.id)
    })
}

const saveItemsOrder = (items: ChecklistItem[], stopReordering: () => void) => {
  itemOrderMutation
    .send({
      checklistId: checklist.value?.id as string,
      order: items.map((item) => item.id),
    })
    .then(() => {
      // Modify the cache before leaving the reorder mode to prevent flickering (e.g. when the subscription is slow) and
      // currently we have the list not in the return data.
      // Here we need no restore because in catch situation we are not leaving the reordering mode.
      modifyItemsCache(items)

      stopReordering()
    })
    .catch(handleUserErrors)
}

const removeItem = async (item: ChecklistItem) => {
  if (item.text?.length) {
    const { waitForVariantConfirmation } = useConfirmation()

    const confirmed = await waitForVariantConfirmation('delete')
    if (!confirmed) return
  }

  const previousChecklistItems = cloneDeep(checklist.value?.items || [])
  apolloCache.evict({ id: apolloCache.identify(item) })
  apolloCache.gc()

  const restoreCache = modifyIncompleteItemCountCache(false)

  addUpdatingItemId(item.id)

  return itemDeleteMutation
    .send({
      checklistId: checklist.value?.id as string,
      checklistItemId: item.id,
    })
    .catch((error) => {
      modifyItemsCache(previousChecklistItems as ChecklistItem[])
      restoreCache()
      return handleUserErrors(error)
    })
    .finally(() => {
      deleteUpdatingItemId(item.id)
    })
}

const checklistActions: MenuItem[] = [
  {
    key: 'rename',
    label: __('Rename checklist'),
    icon: 'input-cursor-text',
    onClick: () => checklistItemsInstance.value?.focusTitle(),
    show: () => !!checklist.value,
  },
  {
    key: 'remove',
    label: __('Remove checklist'),
    variant: 'danger',
    icon: 'trash3',
    onClick: () => removeChecklist(),
    show: () => !!checklist.value,
  },
]

const { isLoadingTemplates, checklistTemplatesMenuItems } =
  useChecklistTemplates(createNewChecklist)
</script>

<template>
  <TicketSidebarContent
    :actions="!isTicketEditable ? undefined : checklistActions"
    :title="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
  >
    <CommonLoader :loading="isLoadingChecklist">
      <div class="flex flex-col gap-3">
        <ChecklistItems
          v-if="checklist"
          ref="checklist-items"
          :no-default-title="!!checklist.name"
          :updating-item-ids="updatingItemIds"
          :title="checklistTitle"
          :items="checklist.items"
          :read-only="!isTicketEditable"
          :is-updating-order="isUpdatingOrder"
          :is-editing-new-item="isAddingNewItem"
          :is-updating-checklist-title="isUpdatingChecklistTitle"
          @add-item="addNewItem"
          @remove-item="removeItem"
          @set-item-checked="setItemCheckedState"
          @edit-item="editItem"
          @save-order="saveItemsOrder"
          @update-title="updateTitle"
        />
        <template v-else-if="isTicketEditable">
          <CommonButton
            variant="primary"
            size="medium"
            block
            :disabled="isAddingNewChecklist"
            @click="createNewChecklist()"
          >
            {{ $t('Add Empty Checklist') }}
          </CommonButton>

          <ChecklistTemplates
            v-if="
              checklistTemplatesMenuItems &&
              checklistTemplatesMenuItems?.length > 0
            "
            :templates="checklistTemplatesMenuItems"
          />
          <ChecklistEmptyTemplates v-else-if="!isLoadingTemplates" />
        </template>
        <CommonLabel v-else>{{
          $t('No checklist added to this ticket yet.')
        }}</CommonLabel>
      </div>
    </CommonLoader>
  </TicketSidebarContent>
</template>
