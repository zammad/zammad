// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import type {
  ChecklistTemplate,
  ChecklistTemplatesQuery,
  ChecklistTemplateUpdatesSubscription,
  ChecklistTemplateUpdatesSubscriptionVariables,
  TicketChecklistAddMutation,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import type { AddNewChecklistInput } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklist/types.ts'
import { useChecklistTemplatesQuery } from '#desktop/pages/ticket/graphql/queries/checklistTemplates.api.ts'
import { ChecklistTemplateUpdatesDocument } from '#desktop/pages/ticket/graphql/subscriptions/checklistTemplateUpdates.api.ts'

type CreateNewChecklist = (
  input?: Omit<AddNewChecklistInput, 'ticketId'>,
  options?: { focusLastItem: boolean },
) => Promise<void | Maybe<TicketChecklistAddMutation>>

export const useChecklistTemplates = (
  createNewChecklist: CreateNewChecklist,
) => {
  const checklistTemplatesQuery = new QueryHandler(
    useChecklistTemplatesQuery(
      {
        onlyActive: true,
      },
      {
        fetchPolicy: 'cache-and-network',
      },
    ),
  )

  const templatesLoading = checklistTemplatesQuery.loading()
  const checklistTemplates = checklistTemplatesQuery.result()

  const isLoadingTemplates = computed(() => {
    // Return already true when an templates exists already in the cache.
    if (checklistTemplates.value !== undefined) return false

    return templatesLoading.value
  })

  checklistTemplatesQuery.subscribeToMore<
    ChecklistTemplateUpdatesSubscriptionVariables,
    ChecklistTemplateUpdatesSubscription
  >({
    document: ChecklistTemplateUpdatesDocument,
    variables: {
      onlyActive: true,
    },
    updateQuery: (_, { subscriptionData }) => {
      if (!subscriptionData.data?.checklistTemplateUpdates.checklistTemplates)
        return null as unknown as ChecklistTemplatesQuery

      return {
        checklistTemplates:
          subscriptionData.data.checklistTemplateUpdates.checklistTemplates,
      }
    },
  })

  const applyChecklistTemplate = async (
    template: Partial<ChecklistTemplate>,
  ) => {
    await createNewChecklist(
      {
        templateId: template.id,
      },
      {
        focusLastItem: false,
      },
    )
  }

  const checklistTemplatesMenuItems = computed(
    () =>
      checklistTemplates.value?.checklistTemplates?.map((data) => ({
        label: data.name as string,
        key: data.id,
        onClick: () => applyChecklistTemplate(data),
      })) || null,
  )
  return { checklistTemplatesMenuItems, isLoadingTemplates }
}
