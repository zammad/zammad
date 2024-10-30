// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { populateEditorNewLines } from '#shared/components/Form/fields/FieldEditor/utils.ts'
import type { FormRef, FormSubmitData } from '#shared/components/Form/types.ts'
import { setErrors } from '#shared/components/Form/utils.ts'
import { useCheckBodyAttachmentReference } from '#shared/composables/form/useCheckBodyAttachmentReference.ts'
import { useObjectAttributeFormData } from '#shared/entities/object-attributes/composables/useObjectAttributeFormData.ts'
import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import { ticketCreateArticleType } from '#shared/entities/ticket/composables/useTicketCreateArticleType.ts'
import { useTicketCreateMutation } from '#shared/entities/ticket/graphql/mutations/create.api.ts'
import UserError from '#shared/errors/UserError.ts'
import {
  EnumObjectManagerObjects,
  type TicketCreateInput,
} from '#shared/graphql/types.ts'
import { isGraphQLId, convertToGraphQLId } from '#shared/graphql/utils.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import { convertFilesToAttachmentInput } from '#shared/utils/files.ts'

import { useTicketCreateView } from './useTicketCreateView.ts'

import type { TicketFormData } from '../types.ts'
import type { ApolloError } from '@apollo/client/core'
import type { Ref } from 'vue'

export const useTicketCreate = (
  form: Ref<FormRef | undefined>,
  redirectAfterCreate: (internalId?: number) => void,
) => {
  const { isTicketCustomer } = useTicketCreateView()

  const { notify } = useNotifications()

  const notifySuccess = () => {
    notify({
      id: 'ticket-create-success',
      type: NotificationTypes.Success,
      message: __('Ticket has been created successfully.'),
    })
  }

  const handleTicketCreateError = (error: UserError | ApolloError) => {
    if ('graphQLErrors' in error) {
      const graphQLErrors = error.graphQLErrors?.[0]

      // Treat this as successful, because it happens when you create a ticket inside a group, where you only
      // have create permission, but not view permission.
      if (graphQLErrors?.extensions?.type === GraphQLErrorTypes.Forbidden) {
        notifySuccess()

        return () => redirectAfterCreate()
      }

      notify({
        id: 'ticket-create-error',
        message: __('Ticket could not be created.'),
        type: NotificationTypes.Error,
      })
    } else {
      if (error instanceof UserError && form.value?.formNode) {
        setErrors(form.value?.formNode, error)
        return
      }

      notify({
        id: 'ticket-create-error',
        message: error.generalErrors[0],
        type: NotificationTypes.Error,
      })
    }
  }

  const ticketCreateMutation = new MutationHandler(
    useTicketCreateMutation({}),
    {
      errorShowNotification: false,
    },
  )

  const {
    missingBodyAttachmentReference,
    bodyAttachmentReferenceConfirmation,
  } = useCheckBodyAttachmentReference()

  const getCustomerVariable = (customerId: string) => {
    return isGraphQLId(customerId) ? { id: customerId } : { email: customerId }
  }

  const createTicket = async (formData: FormSubmitData<TicketFormData>) => {
    // Check for possible missing attached files and ask for confirmation.
    // With return false, the form submit is stopped.
    if (
      missingBodyAttachmentReference(formData.body, formData.attachments) &&
      (await bodyAttachmentReferenceConfirmation())
    ) {
      return false
    }

    const { attributesLookup: ticketObjectAttributesLookup } =
      useObjectAttributes(EnumObjectManagerObjects.Ticket)

    const { internalObjectAttributeValues, additionalObjectAttributeValues } =
      useObjectAttributeFormData(ticketObjectAttributesLookup.value, formData)

    // The customerId has an special handling, so we need to extract it from the internalObjectAttributeValues.
    const { customerId, ...internalValues } = internalObjectAttributeValues

    let sharedDraftId
    if (formData.shared_draft_id) {
      sharedDraftId = convertToGraphQLId(
        'Ticket::SharedDraftStart',
        formData.shared_draft_id as string | number,
      )
    }

    const input = {
      ...internalValues,
      sharedDraftId,
      customer: customerId
        ? getCustomerVariable(customerId as string)
        : undefined,
      article: {
        cc: formData.cc,
        body: populateEditorNewLines(formData.body),
        sender: isTicketCustomer.value
          ? 'Customer'
          : ticketCreateArticleType[formData.articleSenderType].sender,
        type: isTicketCustomer.value
          ? 'web'
          : ticketCreateArticleType[formData.articleSenderType].type,
        contentType: 'text/html',
        security: formData.security,
      },
      objectAttributeValues: additionalObjectAttributeValues,
    } as TicketCreateInput

    if (formData.attachments && input.article && form.value?.formId) {
      input.article.attachments = convertFilesToAttachmentInput(
        form.value.formId,
        formData.attachments,
      )
    }

    if (formData.link_ticket_id) {
      const linkObjectId = convertToGraphQLId(
        'Ticket',
        formData.link_ticket_id as string | number,
      )

      input.links = [
        {
          linkObjectId,
          linkType: 'child',
        },
      ]
    }

    if (formData.externalReferences) {
      input.externalReferences = formData.externalReferences
    }

    return ticketCreateMutation
      .send({ input })
      .then((result) => {
        if (result?.ticketCreate?.ticket) {
          notifySuccess()

          return () => {
            const ticket = result.ticketCreate?.ticket

            redirectAfterCreate(
              ticket?.policy.update ? ticket.internalId : undefined,
            )
          }
        }
        return null
      })
      .catch(handleTicketCreateError)
  }

  return {
    createTicket,
    isTicketCustomer,
  }
}
