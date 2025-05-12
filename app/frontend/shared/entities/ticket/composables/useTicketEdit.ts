// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { isEqual } from 'lodash-es'
import { computed, ref, watch } from 'vue'

import { populateEditorNewLines } from '#shared/components/Form/fields/FieldEditor/utils.ts'
import type {
  FormValues,
  FormRef,
  FormSubmitData,
} from '#shared/components/Form/types.ts'
import { getNodeByName } from '#shared/components/Form/utils.ts'
import { useCheckBodyAttachmentReference } from '#shared/composables/form/useCheckBodyAttachmentReference.ts'
import { useObjectAttributeFormData } from '#shared/entities/object-attributes/composables/useObjectAttributeFormData.ts'
import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import { useTicketUpdateMutation } from '#shared/entities/ticket/graphql/mutations/update.api.ts'
import type {
  TicketArticleReceivedFormValues,
  TicketById,
  TicketUpdateFormData,
} from '#shared/entities/ticket/types.ts'
import type {
  TicketUpdateInput,
  TicketUpdateMetaInput,
} from '#shared/graphql/types.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import type { GraphQLHandlerError } from '#shared/types/error.ts'
import { convertFilesToAttachmentInput } from '#shared/utils/files.ts'

import type { ComputedRef, ShallowRef } from 'vue'

const TICKET_FORM_RELEVANT_KEYS = [
  'id',
  'group',
  'owner',
  'state',
  'pending_time',
  'priority',
  'customer',
  'organization',
  'objectAttributeValues',
]

export const useTicketEdit = (
  ticket: ComputedRef<TicketById | undefined>,
  form: ShallowRef<FormRef | undefined>,
  errorCallback?: (error: GraphQLHandlerError) => boolean,
) => {
  const initialTicketValue = ref<FormValues>()

  const mutationUpdate = new MutationHandler(useTicketUpdateMutation(), {
    errorCallback,
    errorNotificationMessage: __('Ticket update failed.'),
  })

  const ticketFormRelatedData = computed<Partial<TicketById>>(
    (currentTicketFormRelatedData) => {
      if (!ticket.value) return {}

      const newTicketFormRelatedData = (
        TICKET_FORM_RELEVANT_KEYS as Array<keyof TicketById>
      ).reduce<Partial<TicketById>>((relevantData, key) => {
        if (!ticket.value || !(key in ticket.value)) return relevantData

        relevantData[key] = ticket.value[key]

        return relevantData
      }, {})

      if (
        currentTicketFormRelatedData &&
        isEqual(newTicketFormRelatedData, currentTicketFormRelatedData)
      ) {
        return currentTicketFormRelatedData
      }

      return newTicketFormRelatedData
    },
  )

  watch(
    ticketFormRelatedData,
    () => {
      if (!ticket.value) {
        return
      }

      const { internalId: ownerInternalId } = ticket.value.owner

      initialTicketValue.value = {
        id: ticket.value.id,
        owner_id: ownerInternalId === 1 ? null : ownerInternalId,
        isDefaultFollowUpStateSet: undefined, // the default value for reset situations.
      }

      if (!form.value?.formInitialSettled) return

      form.value?.resetForm(
        {
          values: initialTicketValue.value,
          object: ticket.value,
        },
        {
          resetDirty: false,
        },
      )
    },
    { immediate: true },
  )

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
      timeUnit: article.timeUnit,
      accountedTimeTypeId: article.accountedTimeTypeId,
    }
  }

  const {
    missingBodyAttachmentReference,
    bodyAttachmentReferenceConfirmation,
  } = useCheckBodyAttachmentReference()

  const editTicket = async (
    formData: FormSubmitData<TicketUpdateFormData>,
    meta?: TicketUpdateMetaInput,
  ) => {
    if (!ticket.value || !form.value) return undefined

    if (!formData.owner_id) {
      formData.owner_id = 1
    }

    const formArticle = formData.article as
      | TicketArticleReceivedFormValues
      | undefined

    if (
      formArticle &&
      missingBodyAttachmentReference(
        formArticle?.body,
        formArticle?.attachments,
      ) &&
      (await bodyAttachmentReferenceConfirmation())
    ) {
      return undefined
    }

    const article = processArticle(form.value.formId, formArticle)

    const { internalObjectAttributeValues, additionalObjectAttributeValues } =
      useObjectAttributeFormData(ticketObjectAttributesLookup.value, formData)

    const ticketMeta = meta || {}

    let sharedDraftId

    if (formData.shared_draft_id) {
      sharedDraftId = convertToGraphQLId(
        'Ticket::SharedDraftZoom',
        formData.shared_draft_id as string | number,
      )
    }

    return mutationUpdate.send({
      ticketId: ticket.value.id,
      input: {
        ...internalObjectAttributeValues,
        objectAttributeValues: additionalObjectAttributeValues,
        article,
        sharedDraftId,
      } as TicketUpdateInput,
      meta: ticketMeta,
    })
  }

  return {
    initialTicketValue,
    isTicketFormGroupValid,
    editTicket,
  }
}
