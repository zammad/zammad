// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isEqual } from 'lodash-es'
import { computed, ref, watch } from 'vue'

import { transformEditorHtml } from '#shared/components/Form/fields/FieldEditor/utils.ts'
import type { FormValues, FormRef, FormSubmitData } from '#shared/components/Form/types.ts'
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
import type { TicketUpdateInput, TicketUpdateMetaInput } from '#shared/graphql/types.ts'
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
  'pendingTime',
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

  // Values that must be seeded explicitly on a ticket form reset: the form-only
  // fields and the owner_id (system user is represented as null in the form).
  // All other ticket fields should come from the entity object, so server-side
  // changes (e.g. the automatic new->open transition on a reply) are reflected.
  const buildTicketResetValues = (ticketValue: TicketById): FormValues => {
    const { internalId: ownerInternalId } = ticketValue.owner

    return {
      id: ticketValue.id,
      shared_draft_id: undefined,
      owner_id: ownerInternalId === 1 ? null : ownerInternalId,
      isDefaultFollowUpStateSet: undefined, // the default value for reset situations.
    }
  }

  const mutationUpdate = new MutationHandler(useTicketUpdateMutation(), {
    errorCallback,
    errorNotificationMessage: __('Ticket update failed.'),
  })

  const ticketFormRelatedData = computed<Partial<TicketById>>((currentTicketFormRelatedData) => {
    if (!ticket.value) return {}

    const newTicketFormRelatedData = (TICKET_FORM_RELEVANT_KEYS as Array<keyof TicketById>).reduce<
      Partial<TicketById>
    >((relevantData, key) => {
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
  })

  watch(
    ticketFormRelatedData,
    () => {
      if (!ticket.value) return

      initialTicketValue.value = buildTicketResetValues(ticket.value)

      if (!form.value?.formInitialSettled) return

      // Skip the refresh while the own update mutation is running - the form
      // is still dirty with the submitted values and the success handling
      // resets it with the fresh entity data afterwards. A refresh at this
      // point would send the outdated values to the form updater again.
      if (mutationUpdate.loading().value) return

      form.value?.resetForm(
        {
          values: initialTicketValue.value,
          object: ticket.value,
        },
        {
          resetDirty: false,
          resetFlags: false,
        },
      )
    },
    { immediate: true },
  )

  const isTicketFormGroupValid = computed(() => {
    const ticketGroup = form.value?.formNode?.at('ticket')
    return !!ticketGroup?.context?.state.valid
  })

  const { attributesLookup: ticketObjectAttributesLookup } = useObjectAttributes(
    EnumObjectManagerObjects.Ticket,
  )

  const processArticle = (formId: string, article: TicketArticleReceivedFormValues | undefined) => {
    if (!article) return null

    const contentType = getNodeByName(formId, 'body')?.context?.contentType || 'text/html'

    if (contentType === 'text/html') article.body = transformEditorHtml(article.body)

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
    skipAttachmentReferenceCheck,
  } = useCheckBodyAttachmentReference()

  const editTicket = async (
    formData: FormSubmitData<TicketUpdateFormData>,
    meta?: TicketUpdateMetaInput,
  ) => {
    if (!ticket.value || !form.value) return undefined

    if (!formData.owner_id) {
      formData.owner_id = 1
    }

    const formArticle = formData.article as TicketArticleReceivedFormValues | undefined

    if (
      formArticle &&
      missingBodyAttachmentReference(formArticle?.body, formArticle?.attachments) &&
      (await bodyAttachmentReferenceConfirmation())
    ) {
      return undefined
    }

    const article = processArticle(form.value.formId, formArticle)

    const { internalObjectAttributeValues, additionalObjectAttributeValues } =
      useObjectAttributeFormData(
        EnumObjectManagerObjects.Ticket,
        ticketObjectAttributesLookup.value,
        formData,
      )

    const ticketMeta = meta || {}

    let sharedDraftId

    if (formData.shared_draft_id) {
      sharedDraftId = convertToGraphQLId(
        'Ticket::SharedDraftZoom',
        formData.shared_draft_id as string | number,
      )
    }

    return mutationUpdate
      .send({
        ticketId: ticket.value.id,
        input: {
          ...internalObjectAttributeValues,
          objectAttributeValues: additionalObjectAttributeValues,
          article,
          sharedDraftId,
        } as TicketUpdateInput,
        meta: ticketMeta,
      })
      .then((result) => {
        if (result?.ticketUpdate?.ticket) {
          // Reset missingBodyAttachmentReference confirmation prompts
          // after successful ticket update
          skipAttachmentReferenceCheck.value = false
        }
        // Always pass mutation result on
        // so to not change the behavior of the editTicket caller
        // down the line
        return result
      })
  }

  return {
    initialTicketValue,
    isTicketFormGroupValid,
    editTicket,
    buildTicketResetValues,
  }
}
