// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { keyBy } from 'lodash-es'
import { computed, shallowRef } from 'vue'

import type { FieldEditorContext } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { FormHandlerExecution } from '#shared/components/Form/types.ts'
import type {
  ChangedField,
  ReactiveFormSchemData,
  FormHandlerFunction,
  FormRef,
} from '#shared/components/Form/types.ts'
import { useAppName } from '#shared/composables/useAppName.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { createArticleTypes } from '#shared/entities/ticket-article/action/plugins/index.ts'
import type {
  AppSpecificTicketArticleType,
  TicketArticleTypeFields,
} from '#shared/entities/ticket-article/action/plugins/types.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import type { FormKitNode } from '@formkit/core'
import type { Ref } from 'vue'

export const useTicketEditForm = (
  ticket: Ref<TicketById | undefined>,
  form: Ref<FormRef | undefined>,
) => {
  const appName = useAppName()

  const ticketArticleTypes = computed(() => {
    return ticket.value ? createArticleTypes(ticket.value, appName) : []
  })

  const ticketArticleTypeValueLookup = computed(() =>
    keyBy(ticketArticleTypes.value, 'value'),
  )

  const currentArticleType = shallowRef<AppSpecificTicketArticleType>()

  const recipientContact = computed(
    () => currentArticleType.value?.options?.recipientContact,
  )
  const editorType = computed(() => currentArticleType.value?.contentType)

  const editorMeta = computed(() => {
    return {
      mentionText: {
        groupNodeName: 'group_id',
      },
      mentionUser: {
        groupNodeName: 'group_id',
      },
      mentionKnowledgeBase: {
        attachmentsNodeName: 'attachments',
      },
      ...currentArticleType.value?.editorMeta,
    }
  })

  const articleTypeFields = [
    'to',
    'cc',
    'subject',
    'body',
    'attachments',
    'security',
  ] as const

  const articleTypeFieldProps = articleTypeFields.reduce((acc, field) => {
    acc[field] = {
      validation: computed(
        () => currentArticleType.value?.fields?.[field]?.validation || null,
      ),
      required: computed(
        () => !!currentArticleType.value?.fields?.[field]?.required,
      ),
    }

    return acc
  }, {} as TicketArticleTypeFields)

  const { isTicketAgent, isTicketCustomer, isTicketEditable } =
    useTicketView(ticket)

  const isMobileApp = appName === 'mobile'

  const ticketSchema = {
    type: 'group',
    name: 'ticket', // will be flattened in the form submit result
    isGroupOrList: true,
    children: [
      ...(isMobileApp
        ? [
            {
              name: 'title',
              type: 'text',
              label: __('Ticket title'),
              required: true,
            },
          ]
        : []),
      {
        type: 'hidden',
        name: 'isDefaultFollowUpStateSet',
      },
      {
        type: 'hidden',
        name: 'shared_draft_id',
      },
      {
        screen: 'edit',
        object: EnumObjectManagerObjects.Ticket,
      },
    ],
  }

  const articleSchema = {
    // Desktop is handling the condition on top for the teleport.
    if: isMobileApp
      ? '$newTicketArticleRequested || $newTicketArticlePresent'
      : undefined,
    type: 'group',
    name: 'article',
    isGroupOrList: true,
    children: [
      {
        type: 'hidden',
        name: 'inReplyTo',
      },
      {
        if: '$currentArticleType.fields.subtype',
        type: 'hidden',
        name: 'subtype',
      },
      {
        name: 'articleType',
        label: __('Channel'),
        labelSrOnly: isMobileApp,
        type: 'select',
        hidden: computed(() => ticketArticleTypes.value.length === 1),
        props: {
          // We need to disable the auto preselection when the field
          // is initialized, so that we have a correct dirty state.
          noInitialAutoPreselect: true,
          options: ticketArticleTypes,
        },
      },
      {
        name: 'internal',
        label: __('Visibility'),
        labelSrOnly: isMobileApp,
        hidden: isTicketCustomer,
        type: 'select',
        props: {
          options: [
            {
              value: true,
              label: __('Internal'),
              icon: 'lock',
            },
            {
              value: false,
              label: __('Public'),
              icon: 'unlock',
            },
          ],
        },
      },
      {
        if: '$currentArticleType.fields.to',
        name: 'to',
        label: __('To'),
        type: 'recipient',
        validation: articleTypeFieldProps.to.validation,
        props: {
          contact: recipientContact,
          multiple: true,
        },
        required: articleTypeFieldProps.to.required,
      },
      {
        if: '$currentArticleType.fields.cc',
        name: 'cc',
        label: __('CC'),
        type: 'recipient',
        validation: articleTypeFieldProps.cc.validation,
        props: {
          contact: recipientContact,
          multiple: true,
        },
      },
      {
        if: '$currentArticleType.fields.subject',
        name: 'subject',
        label: __('Subject'),
        type: 'text',
        validation: articleTypeFieldProps.subject.validation,
        props: {
          maxlength: 200,
        },
        required: articleTypeFieldProps.subject.required,
      },
      {
        if: '$securityIntegration === true && $currentArticleType.fields.security',
        name: 'security',
        label: __('Security'),
        type: 'security',
        validation: articleTypeFieldProps.security.validation,
      },
      {
        name: 'body',
        screen: 'edit',
        object: EnumObjectManagerObjects.TicketArticle,
        validation: articleTypeFieldProps.body.validation,
        props: {
          ticketId: computed(() => ticket.value?.internalId),
          customerId: computed(() => ticket.value?.customer.internalId),
          contentType: editorType,
          meta: editorMeta,
        },
        required: articleTypeFieldProps.body.required,
      },
      {
        if: '$currentArticleType.fields.attachments',
        type: 'file',
        name: 'attachments',
        label: __('Attachment'),
        labelSrOnly: true,
        validation: articleTypeFieldProps.attachments.validation,
        props: {
          multiple: computed(() =>
            Boolean(
              typeof currentArticleType.value?.fields?.attachments?.multiple ===
                'boolean'
                ? currentArticleType.value?.fields?.attachments?.multiple
                : true,
            ),
          ),
          allowedFiles: computed(
            () =>
              currentArticleType.value?.fields?.attachments?.allowedFiles ||
              null,
          ),
          accept: computed(
            () => currentArticleType.value?.fields?.attachments?.accept || null,
          ),
        },
        required: articleTypeFieldProps.attachments.required,
      },
    ],
  }

  const articleTypeChangeHandler = () => {
    const executeTypeChangeHandler = (
      execution: FormHandlerExecution,
      schemaData: ReactiveFormSchemData,
      changedField?: ChangedField,
    ) => {
      if (!schemaData.fields.articleType) return false
      return !(
        execution === FormHandlerExecution.FieldChange &&
        (!changedField || changedField.name !== 'articleType')
      )
    }

    const handleArticleType: FormHandlerFunction = (
      execution,
      reactivity,
      data,
    ) => {
      const { formNode, changedField, formUpdaterData } = data
      const { schemaData } = reactivity

      if (
        execution === FormHandlerExecution.Initial &&
        formUpdaterData?.fields.articleType?.value
      ) {
        currentArticleType.value =
          ticketArticleTypeValueLookup.value[
            formUpdaterData.fields.articleType.value
          ]
      }

      if (
        !executeTypeChangeHandler(execution, schemaData, changedField) ||
        !ticket.value ||
        !formNode
      )
        return

      const body = formNode.find('body', 'name')
      const context = {
        body: body?.context as unknown as FieldEditorContext,
      }

      if (changedField?.newValue !== changedField?.oldValue) {
        currentArticleType.value?.onDeselected?.(ticket.value, context)
      }

      if (!changedField?.newValue) return
      const newType =
        ticketArticleTypeValueLookup.value[changedField?.newValue as string]
      if (!newType) return

      if (!formNode.context?._open) {
        newType.onSelected?.(ticket.value, context, form.value)
      }
      currentArticleType.value = newType

      formNode.find('internal')?.input(newType.internal, false)
    }

    return {
      execution: [
        FormHandlerExecution.Initial,
        FormHandlerExecution.FieldChange,
      ],
      callback: handleArticleType,
    }
  }

  const articleTypeSelectHandler = (formNode: FormKitNode) => {
    // this is called only when user replied to an article, but the type inside form did not change
    // (because dialog was opened before, and type was changed then, but we still need to trigger select, because visually it's what happens)
    formNode.on('article-reply-open', ({ payload }) => {
      if (!payload || !ticket.value) return

      const articleType = ticketArticleTypeValueLookup.value[payload as string]

      if (!articleType) return
      const body = formNode.find('body', 'name') as FormKitNode
      const context = {
        body: body.context as unknown as FieldEditorContext,
      }
      articleType.onOpened?.(ticket.value, context, form.value)
    })
  }

  const application = useApplicationStore()

  const securityIntegration = computed<boolean>(
    () =>
      (application.config.smime_integration ||
        application.config.pgp_integration) ??
      false,
  )

  return {
    ticketSchema,
    articleSchema,
    currentArticleType,
    ticketArticleTypes,
    securityIntegration,
    isTicketAgent,
    isTicketCustomer,
    isTicketEditable,
    articleTypeHandler: articleTypeChangeHandler,
    articleTypeSelectHandler,
  }
}
