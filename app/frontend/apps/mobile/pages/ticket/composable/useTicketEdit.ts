// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ComputedRef, ShallowRef } from 'vue'
import { computed, reactive, watch } from 'vue'
import { isEqualWith } from 'lodash-es'
import type {
  FormValues,
  FormRef,
  FormSubmitData,
} from '#shared/components/Form/types.ts'
import { useObjectAttributeFormData } from '#shared/entities/object-attributes/composables/useObjectAttributeFormData.ts'
import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import type { TicketUpdateInput } from '#shared/graphql/types.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import type { TicketArticleFormValues } from '#shared/entities/ticket-article/action/plugins/types.ts'
import type { PartialRequired } from '#shared/types/utils.ts'
import { convertFilesToAttachmentInput } from '#shared/utils/files.ts'
import { getNodeByName } from '#shared/components/Form/utils.ts'
import { populateEditorNewLines } from '#shared/components/Form/fields/FieldEditor/utils.ts'
import { useTicketUpdateMutation } from '../graphql/mutations/update.api.ts'

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

  watch(ticket, (newTicket, oldTicket) => {
    if (!newTicket) {
      return
    }

    // We need only to reset the form, when really something was changed (updatedAt is not relevant for the form).
    if (
      isEqualWith(newTicket, oldTicket, (value1, value2, key) => {
        if (key === 'updatedAt') return true
      })
    ) {
      return
    }

    const ticketId = initialTicketValue.id || newTicket.id
    const { internalId: ownerInternalId } = newTicket.owner
    initialTicketValue.id = newTicket.id
    // show Zammad user as empty
    initialTicketValue.owner_id = ownerInternalId === 1 ? null : ownerInternalId

    form.value?.resetForm(initialTicketValue, newTicket, {
      // don't reset to new values, if user changes something
      // if ticket is different, it's probably navigation to another ticket,
      // so we can safely reset the form
      // TODO: navigation to another ticket is currently always a re-render of the form, because of the component key(=newTicket.id) or?
      resetDirty: ticketId !== newTicket.id,
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

    const contentType =
      getNodeByName(formId, 'body')?.context?.contentType || 'text/html'

    if (contentType === 'text/html') {
      article.body = populateEditorNewLines(article.body)
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

  const editTicket = async (formData: FormSubmitData) => {
    if (!ticket.value || !form.value) return undefined

    if (!formData.owner_id) {
      formData.owner_id = 1
    }

    const { internalObjectAttributeValues, additionalObjectAttributeValues } =
      useObjectAttributeFormData(ticketObjectAttributesLookup.value, formData)

    const formArticle = formData.article as
      | TicketArticleReceivedFormValues
      | undefined
    const article = processArticle(form.value.formId, formArticle)

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
