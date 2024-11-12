// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'

import { EnumTicketExternalReferencesIssueTrackerType } from '#shared/graphql/types.ts'

import type { ExternalReferencesFormValues } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/types.ts'
import {
  TicketSidebarButtonBadgeType,
  type TicketSidebarContext,
  TicketSidebarScreenType,
} from '#desktop/pages/ticket/types/sidebar.ts'

export const useIssueTracker = (
  trackerType: EnumTicketExternalReferencesIssueTrackerType,
  context: Ref<TicketSidebarContext>,
) => {
  const isTicketEditable = computed(
    () => context.value.isTicketEditable?.value ?? true, // True for ticket create screen.
  )

  const issueLinks = computed(() => {
    if (context.value.screenType === TicketSidebarScreenType.TicketCreate)
      return (
        (context.value.formValues as ExternalReferencesFormValues)
          .externalReferences?.[trackerType] || []
      )

    return context.value.ticket?.value?.externalReferences?.[trackerType] || []
  })

  const hideSidebar = computed(
    () => !issueLinks.value?.length && !isTicketEditable.value,
  )

  const openIssuesBadge = computed(() =>
    issueLinks.value?.length
      ? {
          label: __('Issues'),
          type: TicketSidebarButtonBadgeType.Info,
          value: issueLinks.value?.length,
        }
      : undefined,
  )

  return { hideSidebar, isTicketEditable, issueLinks, openIssuesBadge }
}
