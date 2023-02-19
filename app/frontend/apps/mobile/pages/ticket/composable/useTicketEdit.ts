// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ComputedRef, ShallowRef } from 'vue'
import { computed, reactive, watch } from 'vue'
import type { FormValues, FormRef, FormData } from '@shared/components/Form'
import { useObjectAttributeFormData } from '@shared/entities/object-attributes/composables/useObjectAttributeFormData'
import { useObjectAttributes } from '@shared/entities/object-attributes/composables/useObjectAttributes'
import type { TicketUpdateInput } from '@shared/graphql/types'
import { EnumObjectManagerObjects } from '@shared/graphql/types'
import { MutationHandler } from '@shared/server/apollo/handler'
import type { TicketById } from '@shared/entities/ticket/types'
import type { TicketArticleFormValues } from '@shared/entities/ticket-article/action/plugins/types'
import { getNode } from '@formkit/core'
import type { PartialRequired } from '@shared/types/utils'
import { convertFilesToAttachmentInput } from '@shared/utils/files'
import { useTicketUpdateMutation } from '../graphql/mutations/update.api'

type TicketArticleReceivedFormValues = PartialRequired<
  TicketArticleFormValues,
  // form always has these values
  'articleType' | 'body' | 'internal'
>

export const useTicketEdit = (
  ticket: ComputedRef<TicketById | undefined>,
  form: ShallowRef<FormRef | undefined>,
) => {
  const initialTicketValue = reactive<FormValues>({})
  const mutationUpdate = new MutationHandler(useTicketUpdateMutation({}))

  watch(ticket, (ticket) => {
    if (!ticket) {
      return
    }
    const ticketId = initialTicketValue.id || ticket.id
    const { internalId: ownerInternalId } = ticket.owner
    initialTicketValue.id = ticket.id
    // show Zammad user as empty
    initialTicketValue.owner_id = ownerInternalId === 1 ? null : ownerInternalId

    form.value?.resetForm(initialTicketValue, ticket, {
      // don't reset to new values, if user changes something
      // if ticket is different, it's probably navigation to another ticket,
      // so we can safely reset the form
      resetDirty: ticketId !== ticket.id,
    })
  })

  const isTicketFormGroupValid = computed(() => {
    const ticketGroup = form.value?.formNode?.at('ticket')
    return !!ticketGroup?.context?.state.valid
  })

  const { attributesLookup: ticketObjectAttributesLookup } =
    useObjectAttributes(EnumObjectManagerObjects.Ticket)

  const processArticle = (
    formId: string,
    article: TicketArticleReceivedFormValues | undefined,
  ) => {
    if (!article) return null

    const contentType = getNode('body')?.context?.contentType || 'text/html'

    if (contentType === 'text/html') {
      const body = document.createElement('div')
      body.innerHTML = article.body
      // TODO: https://github.com/zammad/coordination-feature-mobile-view/issues/396
      // prosemirror always adds a visible linebreak inside an empty paragraph,
      // but it doesn't return it inside a schema, so we need to add it manually
      body.querySelectorAll('p').forEach((p) => {
        p.removeAttribute('data-marker')
        if (
          p.childNodes.length === 0 ||
          p.lastChild?.nodeType !== Node.TEXT_NODE ||
          p.textContent?.endsWith('\n')
        ) {
          p.appendChild(document.createElement('br'))
        }
      })
      article.body = body.innerHTML
    }

    return {
      type: article.articleType,
      body: article.body,
      internal: article.internal,
      cc: article.cc,
      to: article.to,
      subject: article.subject,
      subtype: article.subtype,
      inReplyTo: article.inReplyTo,
      contentType,
      attachments: convertFilesToAttachmentInput(formId, article.attachments),
      security: article.security,
    }
  }

  const editTicket = async (formData: FormData) => {
    if (!ticket.value) return undefined

    if (!formData.owner_id) {
      formData.owner_id = 1
    }

    const { internalObjectAttributeValues, additionalObjectAttributeValues } =
      useObjectAttributeFormData(ticketObjectAttributesLookup.value, formData)

    const formArticle = formData.article as
      | TicketArticleReceivedFormValues
      | undefined
    const article = processArticle(formData.formId, formArticle)

    return mutationUpdate.send({
      ticketId: ticket.value.id,
      input: {
        ...internalObjectAttributeValues,
        objectAttributeValues: additionalObjectAttributeValues,
        article,
      } as TicketUpdateInput,
    })
  }

  return {
    initialTicketValue,
    isTicketFormGroupValid,
    editTicket,
  }
}
