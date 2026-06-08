// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormRef, FormValues } from '#shared/components/Form/types.ts'
import { useTicketSharedDraftStartDeleteMutation } from '#shared/entities/ticket-shared-draft-start/graphql/mutations/ticketSharedDraftStartDelete.api.ts'
import { useTicketSharedDraftStartSingleQuery } from '#shared/entities/ticket-shared-draft-start/graphql/queries/ticketSharedDraftStartSingle.api.ts'
import { useTicketSharedDraftZoomDeleteMutation } from '#shared/entities/ticket-shared-draft-zoom/graphql/mutations/ticketSharedDraftZoomDelete.api.ts'
import { useTicketSharedDraftZoomShowQuery } from '#shared/entities/ticket-shared-draft-zoom/graphql/queries/ticketSharedDraftZoomShow.api.ts'
import { removeSignatureFromBody } from '#shared/utils/dom.ts'

import { openFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'

export const useTicketSharedDraft = () => {
  const mapSharedDraftParams = (ticketId: string, form?: FormRef) => {
    const { article: newArticle, ...ticketAttributes }: { article?: FormValues } =
      form?.values || {}

    // Map values to the expected format
    if (newArticle) {
      newArticle.type = newArticle.articleType
      newArticle.to = ((newArticle.to as string[]) || []).join(', ')
      newArticle.cc = ((newArticle.cc as string[]) || []).join(', ')
      newArticle.body = removeSignatureFromBody(newArticle.body, true)
    }

    return {
      ticketId,
      formId: form?.formId as string,
      newArticle: newArticle || {},
      ticketAttributes,
    }
  }

  const openSharedDraftFlyout = (
    draftType: 'start' | 'detail-view',
    sharedDraftId?: string | null,
    form?: FormRef,
  ) => {
    openFlyout(
      'shared-draft',
      {
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
      },
      true, // global
    )
  }

  return {
    mapSharedDraftParams,
    openSharedDraftFlyout,
  }
}
