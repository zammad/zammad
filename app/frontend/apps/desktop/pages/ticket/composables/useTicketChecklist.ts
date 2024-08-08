// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { watchOnce } from '@vueuse/shared'
import { computed, nextTick, type Ref, watch } from 'vue'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import type {
  ChecklistItem,
  ChecklistTemplate,
  ChecklistTemplateUpdatesSubscription,
  ChecklistTemplateUpdatesSubscriptionVariables,
  InputMaybe,
  TicketChecklistItemInput,
  TicketChecklistQuery,
  TicketChecklistUpdatesSubscription,
  TicketChecklistUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'
import {
  MutationHandler,
  QueryHandler,
} from '#shared/server/apollo/handler/index.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import { findChangedIndex } from '#shared/utils/helpers.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import type ChecklistItems from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklistContent/ChecklistItems.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { useTicketNumber } from '#desktop/pages/ticket/composables/useTicketNumber.ts'
import { useTicketChecklistAddMutation } from '#desktop/pages/ticket/graphql/mutations/ticketChecklistAdd.api.ts'
import { useTicketChecklistDeleteMutation } from '#desktop/pages/ticket/graphql/mutations/ticketChecklistDelete.api.ts'
import { useTicketChecklistItemDeleteMutation } from '#desktop/pages/ticket/graphql/mutations/ticketChecklistItemDelete.api.ts'
import { useTicketChecklistItemOrderUpdateMutation } from '#desktop/pages/ticket/graphql/mutations/ticketChecklistItemOrderUpdate.api.ts'
import { useTicketChecklistItemUpsertMutation } from '#desktop/pages/ticket/graphql/mutations/ticketChecklistItemUpsert.api.ts'
import { useTicketChecklistTitleUpdateMutation } from '#desktop/pages/ticket/graphql/mutations/ticketChecklistTitleUpdate.api.ts'
import { useChecklistTemplatesQuery } from '#desktop/pages/ticket/graphql/queries/checklistTemplates.api.ts'
import { useTicketChecklistQuery } from '#desktop/pages/ticket/graphql/queries/ticketChecklist.api.ts'
import { ChecklistTemplateUpdatesDocument } from '#desktop/pages/ticket/graphql/subscriptions/checklistTemplateUpdates.api.ts'

import { TicketChecklistUpdatesDocument } from '../graphql/subscriptions/ticketChecklistUpdates.api.ts'

type AddNewChecklistArgs = {
  ticketId?: InputMaybe<string>
  ticketInternalId?: InputMaybe<number>
  ticketNumber?: InputMaybe<string>
  templateId?: InputMaybe<string>
}

export const useTicketChecklist = (
  checklistItemsComponent: Ref<InstanceType<typeof ChecklistItems>>,
) => {
  const { ticket } = useTicketInformation()
  const { ticketNumberWithTicketHook } = useTicketNumber(ticket)

  const readOnly = computed(() => !ticket.value?.policy.update)

  const checklistQuery = new QueryHandler(
    useTicketChecklistQuery(
      () => ({
        ticketId: ticket.value?.id,
      }),
      {
        fetchPolicy: 'cache-and-network',
      },
    ),
    {
      errorCallback: (error) => error.type !== GraphQLErrorTypes.RecordNotFound,
    },
  )

  const checklistResult = checklistQuery.result()
  const isLoadingChecklist = checklistQuery.loading()
  const checklist = computed(() => checklistResult.value?.ticketChecklist)

  const subscribeToChecklistUpdates = () => {
    checklistQuery.subscribeToMore<
      TicketChecklistUpdatesSubscriptionVariables,
      TicketChecklistUpdatesSubscription
    >({
      document: TicketChecklistUpdatesDocument,
      variables: {
        ticketId: ticket.value?.id,
      },
      updateQuery: (prev, { subscriptionData }) => {
        if (!subscriptionData.data.ticketChecklistUpdates)
          return null as unknown as TicketChecklistQuery

        const { ticketChecklist } = subscriptionData.data.ticketChecklistUpdates

        if (checklist.value?.items?.length && ticketChecklist?.items?.length) {
          const index = findChangedIndex(
            checklist.value.items,
            ticketChecklist.items,
          )
          if (index >= 0) checklistItemsComponent.value?.quitItemEditing(index)
        }

        return {
          ticketChecklist,
        }
      },
    })
  }

  watch(
    () => ticket.value?.id,
    (newTicketId, oldTicketId) => {
      if (!newTicketId) return
      if (newTicketId !== oldTicketId) {
        subscribeToChecklistUpdates()
      }
    },
    { immediate: true },
  )

  watch(checklist, async (newChecklist, oldChecklist) => {
    if (
      (newChecklist?.items?.length ?? 0) <= (oldChecklist?.items?.length ?? 0) // If new checklist item got appended
    )
      return

    await nextTick()
    checklistItemsComponent.value?.focusNewItem()
  })

  const addNewChecklistMutation = new MutationHandler(
    useTicketChecklistAddMutation(),
  )

  const checklistTitle = computed(
    () =>
      checklist.value?.name ||
      i18n.t('%s Checklist', ticketNumberWithTicketHook.value),
  )

  const createNewChecklist = async (
    args?: Omit<AddNewChecklistArgs, 'ticketId'>,
  ) => {
    await addNewChecklistMutation.send({
      ...args,
      ticketId: ticket.value?.id,
    })
    watchOnce(checklistItemsComponent, (component) => {
      nextTick(() => component.focusNewItem())
    })
  }

  // CHECKLIST TITLE ACTIONS

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
      await checklistDeleteMutation.send({
        checklistId: checklist.value?.id as string,
      })
  }

  const updateTitle = async (title: string) => {
    await checklistTitleUpdateMutation.send({
      title,
      checklistId: checklist.value?.id as string,
    })
  }

  // CHECKLIST ITEM ACTIONS

  const itemUpsertMutation = new MutationHandler(
    useTicketChecklistItemUpsertMutation(),
  )

  const itemOrderMutation = new MutationHandler(
    useTicketChecklistItemOrderUpdateMutation(),
  )

  const itemDeleteMutation = new MutationHandler(
    useTicketChecklistItemDeleteMutation(),
  )

  const updateItem = async (
    itemId: string,
    input: TicketChecklistItemInput,
  ) => {
    await itemUpsertMutation.send({
      checklistId: checklist.value?.id as string,
      checklistItemId: itemId,
      input,
    })
  }

  const setItemCheckedState = async (item: ChecklistItem) => {
    await updateItem(item.id, { checked: item.checked })
  }

  const addNewItem = async () => {
    await itemUpsertMutation.send({
      checklistId: checklist.value?.id as string,
      input: {
        text: '',
        checked: false,
      },
    })
  }

  const editItem = async (item: ChecklistItem) => {
    await updateItem(item.id, { text: item.text })
  }

  const saveItemsOrder = async (items: ChecklistItem[]) => {
    await itemOrderMutation.send({
      checklistId: checklist.value?.id as string,
      order: items.map((item) => item.id),
    })
  }

  const removeItem = async (item: ChecklistItem) => {
    if (!item.text?.length)
      return itemDeleteMutation.send({
        checklistId: checklist.value?.id as string,
        checklistItemId: item.id,
      })

    const { waitForVariantConfirmation } = useConfirmation()

    const confirmed = await waitForVariantConfirmation('delete')

    if (confirmed)
      return itemDeleteMutation.send({
        checklistId: checklist.value?.id as string,
        checklistItemId: item.id,
      })
  }

  const checklistActions: MenuItem[] = [
    {
      key: 'rename',
      label: __('Rename checklist'),
      icon: 'input-cursor-text',
      onClick: () => checklistItemsComponent.value?.focusTitle(),
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

  //  CHECKLIST TEMPLATES
  const checklistTemplatesQuery = useChecklistTemplatesQuery(
    {
      onlyActive: true,
    },
    {
      fetchPolicy: 'cache-and-network',
    },
  )

  const isLoadingTemplates = checklistTemplatesQuery.loading

  checklistTemplatesQuery.subscribeToMore<
    ChecklistTemplateUpdatesSubscriptionVariables,
    ChecklistTemplateUpdatesSubscription
  >({
    document: ChecklistTemplateUpdatesDocument,
    variables: {
      onlyActive: true,
    },
    updateQuery: (prev, { subscriptionData }) => {
      if (!subscriptionData.data?.checklistTemplateUpdates?.checklistTemplates)
        return {
          checklistTemplates: prev.checklistTemplates || [],
        }

      return {
        checklistTemplates:
          subscriptionData.data.checklistTemplateUpdates.checklistTemplates,
      }
    },
  })

  const applyChecklistTemplate = async (
    template: Partial<ChecklistTemplate>,
  ) => {
    await createNewChecklist({
      templateId: template.id,
    })
  }

  const checklistTemplates = computed(
    () =>
      checklistTemplatesQuery.result.value?.checklistTemplates.map((data) => ({
        label: data.name as string,
        key: data.id,
        onClick: () => applyChecklistTemplate(data),
      })) || null,
  )

  return {
    addNewItem,
    checklist,
    checklistTemplates,
    checklistTitle,
    createNewChecklist,
    setItemCheckedState,
    removeItem,
    saveItemsOrder,
    editItem,
    updateTitle,
    readOnly,
    checklistActions,
    isLoading: computed(
      () => isLoadingChecklist.value || isLoadingTemplates.value,
    ),
  }
}
