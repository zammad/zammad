// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { FormHandlerExecution } from '#shared/components/Form/types.ts'
import { createArticleTypes } from '#shared/entities/ticket-article/action/plugins/index.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import { computed, shallowRef } from 'vue'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import type { AppSpecificTicketArticleType } from '#shared/entities/ticket-article/action/plugins/types.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import type { ComputedRef, Ref } from 'vue'
import type {
  ChangedField,
  ReactiveFormSchemData,
  FormHandlerFunction,
} from '#shared/components/Form/types.ts'
import type { FieldEditorContext } from '#shared/components/Form/fields/FieldEditor/types.ts'
import type { FormKitNode } from '@formkit/core'

export const useTicketEditForm = (ticket: Ref<TicketById | undefined>) => {
  const ticketArticleTypes = computed(() => {
    return ticket.value ? createArticleTypes(ticket.value, 'mobile') : []
  })

  const currentArticleType = shallowRef<AppSpecificTicketArticleType>()

  const recipientContact = computed(
    () => currentArticleType.value?.options?.recipientContact,
  )
  const editorType = computed(() => currentArticleType.value?.contentType)

  const editorMeta = computed(() => {
    return {
      mentionUser: {
        groupNodeName: 'group_id',
      },
      mentionKnowledgeBase: {
        attachmentsNodeName: 'attachments',
      },
      ...currentArticleType.value?.editorMeta,
    }
  })

  const validationFields = [
    'to',
    'cc',
    'subject',
    'body',
    'attachments',
    'security',
  ]

  const validations = validationFields.reduce(
    (
      acc: Record<
        string,
        ComputedRef<null | string | Array<[rule: string, ...args: unknown[]]>>
      >,
      field,
    ) => {
      acc[field] = computed(
        () => currentArticleType.value?.validation?.[field] || null,
      )
      return acc
    },
    {},
  )

  const { isTicketCustomer } = useTicketView(ticket)

  const ticketSchema = {
    type: 'group',
    name: 'ticket', // will be flattened in the form submit result
    isGroupOrList: true,
    children: [
      {
        name: 'title',
        type: 'text',
        label: __('Ticket title'),
        required: true,
      },
      {
        type: 'hidden',
        name: 'isDefaultFollowUpStateSet',
      },
      {
        screen: 'edit',
        object: EnumObjectManagerObjects.Ticket,
      },
    ],
  }

  const articleSchema = {
    if: '$newTicketArticleRequested || $newTicketArticlePresent',
    type: 'group',
    name: 'article',
    isGroupOrList: true,
    children: [
      {
        type: 'hidden',
        name: 'inReplyTo',
      },
      {
        if: '$fns.includes($currentArticleType.attributes, "subtype")',
        type: 'hidden',
        name: 'subtype',
      },
      {
        name: 'articleType',
        label: __('Article Type'),
        labelSrOnly: true,
        type: 'select',
        hidden: computed(() => ticketArticleTypes.value.length === 1),
        props: {
          options: ticketArticleTypes,
        },
      },
      {
        name: 'internal',
        label: __('Visibility'),
        labelSrOnly: true,
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
        triggerFormUpdater: false,
      },
      {
        if: '$fns.includes($currentArticleType.attributes, "to")',
        name: 'to',
        label: __('To'),
        type: 'recipient',
        validation: validations.to,
        props: {
          contact: recipientContact,
          multiple: true,
        },
      },
      {
        if: '$fns.includes($currentArticleType.attributes, "cc")',
        name: 'cc',
        label: __('CC'),
        type: 'recipient',
        validation: validations.сс,
        props: {
          contact: recipientContact,
          multiple: true,
        },
      },
      {
        if: '$fns.includes($currentArticleType.attributes, "subject")',
        name: 'subject',
        label: __('Subject'),
        type: 'text',
        validation: validations.subject,
        props: {
          maxlength: 200,
        },
        triggerFormUpdater: false,
      },
      {
        if: '$securityIntegration === true && $fns.includes($currentArticleType.attributes, "security")',
        name: 'security',
        label: __('Security'),
        type: 'security',
        validation: validations.security,
        triggerFormUpdater: false,
      },
      {
        name: 'body',
        screen: 'edit',
        object: EnumObjectManagerObjects.TicketArticle,
        validation: validations.body,
        props: {
          ticketId: computed(() => ticket.value?.internalId),
          customerId: computed(() => ticket.value?.customer.internalId),
          contentType: editorType,
          meta: editorMeta,
        },
        triggerFormUpdater: true,
        required: true,
      },
      {
        if: '$fns.includes($currentArticleType.attributes, "attachments")',
        type: 'file',
        name: 'attachments',
        validation: validations.attachments,
        props: {
          multiple: computed((): boolean =>
            typeof currentArticleType.value?.options?.multipleUploads ===
            'boolean'
              ? currentArticleType.value?.options?.multipleUploads
              : true,
          ),
        },
      },
    ],
  }

  const ticketEditSchema = [
    {
      isLayout: true,
      component: 'FormGroup',
      props: {
        style: {
          if: '$formLocation !== "[data-ticket-edit-form]"',
          then: 'display: none;',
        },
        showDirtyMark: true,
      },
      children: [ticketSchema],
    },
    {
      isLayout: true,
      component: 'FormGroup',
      props: {
        style: {
          if: '$formLocation !== "[data-ticket-article-reply-form]"',
          then: 'display: none;',
        },
      },
      children: [articleSchema],
    },
  ]

  const articleTypeChangeHandler = () => {
    const executeHandler = (
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
      const { formNode, changedField } = data
      const { schemaData } = reactivity

      if (
        !executeHandler(execution, schemaData, changedField) ||
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

      const newType = ticketArticleTypes.value.find(
        (type) => type.value === changedField?.newValue,
      )
      if (!newType) return

      if (!formNode.context?._open) {
        newType.onSelected?.(ticket.value, context)
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
      const articleType = ticketArticleTypes.value.find(
        (type) => type.value === payload,
      )
      if (!articleType) return
      const body = formNode.find('body', 'name') as FormKitNode
      const context = {
        body: body.context as unknown as FieldEditorContext,
      }
      articleType.onOpened?.(ticket.value, context)
    })
  }

  return {
    ticketEditSchema,
    currentArticleType,
    articleTypeHandler: articleTypeChangeHandler,
    articleTypeSelectHandler,
  }
}
