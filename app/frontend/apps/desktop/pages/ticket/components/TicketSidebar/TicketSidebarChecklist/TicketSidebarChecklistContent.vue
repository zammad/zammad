<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script lang="ts" setup>
import { cloneDeep } from 'lodash-es'
import { computed, watch, nextTick, useTemplateRef } from 'vue'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { handleUserErrors } from '#shared/errors/utils.ts'
import type {
  ChecklistItem,
  TicketChecklistItemInput,
  TicketChecklistQuery,
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

interface Props extends TicketSidebarContentProps {
  checklist?: TicketChecklistQuery['ticketChecklist']
  loading: boolean
  readonly: boolean
}

const props = defineProps<Props>()

const checklistItemsInstance = useTemplateRef('checklist-items')

const { cache: apolloCache } = getApolloClient()

const { ticket } = useTicketInformation()
const { ticketNumberWithTicketHook } = useTicketNumber(ticket)
const checklistTitle = computed(
  () =>
    props.checklist?.name ||
    i18n.t('%s Checklist', ticketNumberWithTicketHook.value),
)

const addNewChecklistMutation = new MutationHandler(
  useTicketChecklistAddMutation(),
)

const createNewChecklist = async (
  input?: Omit<AddNewChecklistInput, 'ticketId'>,
  options = { focusLastItem: true },
) => {
  if (options.focusLastItem)
    watch(
      checklistItemsInstance,
      (component) => {
        nextTick(() => component?.focusNewItem())
      },
      { once: true },
    )

  if (ticket.value?.id) {
    return addNewChecklistMutation
      .send({
        ...input,
        ticketId: ticket.value.id,
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
        checklistId: props.checklist?.id as string,
      })
      .catch(handleUserErrors)
}

const updateTitle = async (title: string) => {
  return checklistTitleUpdateMutation
    .send({
      title,
      checklistId: props.checklist?.id as string,
    })
    .then(() => {})
    .catch(handleUserErrors)
}

const itemAddMutation = new MutationHandler(
  useTicketChecklistItemUpsertMutation({
    update: (cache, { data }) => {
      if (!data || !props.checklist) return

      const { ticketChecklistItemUpsert } = data
      if (!ticketChecklistItemUpsert?.checklistItem) return

      const newIdPresent = props.checklist?.items.find((item) => {
        return item.id === ticketChecklistItemUpsert.checklistItem?.id
      })
      if (newIdPresent) return

      cache.modify({
        id: cache.identify(props.checklist),
        fields: {
          items(currentItems, { toReference }) {
            return [
              ...currentItems,
              toReference(ticketChecklistItemUpsert.checklistItem!),
            ]
          },
          incomplete() {
            return (props.checklist?.incomplete || 0) + 1
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

const modifyIncompleteItemCountCache = (increase: boolean) => {
  const currentCheckList = props.checklist!
  const previousIncomplteItemCount = currentCheckList.incomplete
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
      completed() {
        return incompleteItemCount === 0
      },
    },
  })

  // Return function to restore cache to the previous state.
  return () => {
    apolloCache.modify({
      id: checklistId,
      fields: {
        incomplete() {
          return previousIncomplteItemCount
        },
        completed() {
          return previousCompleted
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
  const currentCheckList = props.checklist!

  const checklistId = apolloCache.identify(currentCheckList)

  apolloCache.modify({
    id: checklistId,
    fields: {
      items(_, { toReference }) {
        // We need to transform it to an real reference, that we do not loose the connection.
        // Side effect is that data updates on single items are not applied.
        return items.map((item) => toReference(item, true))
      },
    },
  })
}

const updateItem = async (itemId: string, input: TicketChecklistItemInput) => {
  return itemUpsertMutation.send({
    checklistId: props.checklist?.id as string,
    checklistItemId: itemId,
    input,
  })
}

const setItemCheckedState = async (item: ChecklistItem) => {
  const restoreCache = modifyCheckedCache(item)
  await updateItem(item.id, { checked: item.checked }).catch((error) => {
    restoreCache()
    handleUserErrors(error)
  })
}

const addNewItem = async () => {
  watch(
    () => props.checklist,
    () => {
      nextTick(() => checklistItemsInstance.value?.focusNewItem())
    },
    { once: true },
  )

  return itemAddMutation
    .send({
      checklistId: props.checklist?.id as string,
      input: {
        text: '',
        checked: false,
      },
    })
    .catch(handleUserErrors)
}

const editItem = async (item: ChecklistItem) => {
  return updateItem(item.id, { text: item.text })
    .then(() => {})
    .catch(handleUserErrors)
}

const saveItemsOrder = (items: ChecklistItem[], stopReordering: () => void) => {
  itemOrderMutation
    .send({
      checklistId: props.checklist?.id as string,
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

  const previousChecklistItems = cloneDeep(props.checklist?.items || [])
  apolloCache.evict({ id: apolloCache.identify(item) })
  apolloCache.gc()

  const restoreCache = modifyIncompleteItemCountCache(false)

  return itemDeleteMutation
    .send({
      checklistId: props.checklist?.id as string,
      checklistItemId: item.id,
    })
    .catch((error) => {
      modifyItemsCache(previousChecklistItems as ChecklistItem[])
      restoreCache()
      return handleUserErrors(error)
    })
}

const checklistActions: MenuItem[] = [
  {
    key: 'rename',
    label: __('Rename checklist'),
    icon: 'input-cursor-text',
    onClick: () => checklistItemsInstance.value?.focusTitle(),
    show: () => !!props.checklist,
  },
  {
    key: 'remove',
    label: __('Remove checklist'),
    variant: 'danger',
    icon: 'trash3',
    onClick: () => removeChecklist(),
    show: () => !!props.checklist,
  },
]

const { isLoadingTemplates, checklistTemplatesMenuItems } =
  useChecklistTemplates(createNewChecklist)
</script>

<template>
  <TicketSidebarContent
    :actions="readonly ? undefined : checklistActions"
    :title="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
  >
    <CommonLoader :loading="loading">
      <div class="flex flex-col gap-3">
        <ChecklistItems
          v-if="checklist"
          ref="checklist-items"
          :no-default-title="!!checklist.name"
          :title="checklistTitle"
          :items="<ChecklistItem[]>checklist?.items"
          :read-only="readonly"
          @add-item="addNewItem"
          @remove-item="removeItem"
          @set-item-checked="setItemCheckedState"
          @edit-item="editItem"
          @save-order="saveItemsOrder"
          @update-title="updateTitle"
        />
        <template v-else-if="!readonly">
          <CommonButton
            variant="primary"
            size="medium"
            block
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
