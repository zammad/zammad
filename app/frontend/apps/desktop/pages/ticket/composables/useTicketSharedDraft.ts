// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { FormRef, FormValues } from '#shared/components/Form/types.ts'
import { useTicketSharedDraftStartDeleteMutation } from '#shared/entities/ticket-shared-draft-start/graphql/mutations/ticketSharedDraftStartDelete.api.ts'
import { useTicketSharedDraftStartSingleQuery } from '#shared/entities/ticket-shared-draft-start/graphql/queries/ticketSharedDraftStartSingle.api.ts'
import { useTicketSharedDraftZoomDeleteMutation } from '#shared/entities/ticket-shared-draft-zoom/graphql/mutations/ticketSharedDraftZoomDelete.api.ts'
import { useTicketSharedDraftZoomShowQuery } from '#shared/entities/ticket-shared-draft-zoom/graphql/queries/ticketSharedDraftZoomShow.api.ts'
import { removeSignatureFromBody } from '#shared/utils/dom.ts'

import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'

export const useTicketSharedDraft = (
  setSkipNextStateUpdate?: (skip: boolean) => void,
) => {
  const mapSharedDraftParams = (ticketId: string, form?: FormRef) => {
    const {
      article: newArticle,
      ...ticketAttributes
    }: { article?: FormValues } = form?.values || {}

    // Map values to the expected format
    if (newArticle) {
      newArticle.type = newArticle.articleType
      newArticle.to = ((newArticle.to as string[]) || []).join(', ')
      newArticle.cc = ((newArticle.cc as string[]) || []).join(', ')
      newArticle.body = removeSignatureFromBody(newArticle.body)
    }

    return {
      ticketId,
      formId: form?.formId as string,
      newArticle: newArticle || {},
      ticketAttributes,
    }
  }

  const sharedDraftFlyout = useFlyout({
    name: 'shared-draft',
    component: () => import('../components/TicketSharedDraftFlyout.vue'),
  })

  const openSharedDraftFlyout = (
    draftType: 'start' | 'detail-view',
    sharedDraftId?: string | null,
    form?: FormRef,
  ) => {
    sharedDraftFlyout.open({
      sharedDraftId,
      form,
      draftType,
      metaInformationQuery:
        draftType === 'start'
          ? useTicketSharedDraftStartSingleQuery
          : useTicketSharedDraftZoomShowQuery,
      deleteMutation:
        draftType === 'start'
          ? useTicketSharedDraftStartDeleteMutation
          : useTicketSharedDraftZoomDeleteMutation,
      setSkipNextStateUpdate,
    })
  }

  return {
    mapSharedDraftParams,
    openSharedDraftFlyout,
  }
}
