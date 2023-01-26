// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormHandlerFunction } from '@shared/components/Form'
import { FormHandlerExecution } from '@shared/components/Form'
import { createArticleTypes } from '@shared/entities/ticket-article/action/plugins'
import type { AppSpecificTicketArticleType } from '@shared/entities/ticket-article/action/plugins/types'
import type { TicketById } from '@shared/entities/ticket/types'
import { useTicketView } from '@shared/entities/ticket/composables/useTicketView'
import { EnumObjectManagerObjects } from '@shared/graphql/types'
import type { Ref } from 'vue'
import { computed, shallowRef } from 'vue'
import type {
  ChangedField,
  ReactiveFormSchemData,
} from '@shared/components/Form/types'

export const useTicketEditForm = (ticket: Ref<TicketById | undefined>) => {
  const ticketArticleTypes = computed(() => {
    return ticket.value ? createArticleTypes(ticket.value, 'mobile') : []
  })

  const currentArticleType = shallowRef<AppSpecificTicketArticleType>()

  const editorType = computed(() => currentArticleType.value?.contentType)

  const editorMeta = computed(() => {
    return {
      mentionUser: {
        groupNodeId: 'group_id',
      },
      ...currentArticleType?.value?.editorMeta,
    }
  })

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
        name: 'articleType',
        label: __('Article Type'),
        labelSrOnly: true,
        type: 'select',
        hidden: computed(() => ticketArticleTypes.value.length === 1),
        props: {
          options: ticketArticleTypes,
        },
        triggerFormUpdater: false,
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
              icon: 'mobile-lock',
            },
            {
              value: false,
              label: __('Public'),
              icon: 'mobile-unlock',
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
        props: {
          multiple: true,
        },
        triggerFormUpdater: false,
      },
      {
        if: '$fns.includes($currentArticleType.attributes, "cc")',
        name: 'cc',
        label: __('CC'),
        type: 'recipient',
        props: {
          multiple: true,
        },
        triggerFormUpdater: false,
      },
      {
        if: '$fns.includes($currentArticleType.attributes, "subject")',
        name: 'subject',
        label: __('Subject'),
        type: 'text',
        props: {
          maxlength: 200,
        },
        triggerFormUpdater: false,
      },
      {
        if: '$fns.includes($currentArticleType.attributes, "security")',
        name: 'security',
        label: __('Security'),
        type: 'security',
        props: {
          // TODO ...
        },
        triggerFormUpdater: false,
      },
      {
        name: 'body',
        screen: 'edit',
        object: EnumObjectManagerObjects.TicketArticle,
        props: {
          contentType: editorType,
          meta: editorMeta,
        },
        triggerFormUpdater: false,
        required: true, // debug
      },
      {
        if: '$fns.includes($currentArticleType.attributes, "attachments")',
        type: 'file',
        name: 'attachments',
        props: {
          multiple: true,
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

  const articleTypeHandler = () => {
    const executeHandler = (
      execution: FormHandlerExecution,
      schemaData: ReactiveFormSchemData,
      changedField?: ChangedField,
    ) => {
      if (!schemaData.fields.articleType) return false
      if (
        execution === FormHandlerExecution.FieldChange &&
        (!changedField || changedField.name !== 'articleType')
      ) {
        return false
      }

      return true
    }

    const handleArticleType: FormHandlerFunction = (
      execution,
      formNode,
      values,
      changeFields,
      updateSchemaDataField,
      schemaData,
      changedField,
    ) => {
      if (!executeHandler(execution, schemaData, changedField) || !ticket.value)
        return

      if (changedField?.newValue !== changedField?.oldValue) {
        currentArticleType.value?.onDeselected?.(ticket.value)
      }

      const newType = ticketArticleTypes.value.find(
        (type) => type.value === changedField?.newValue,
      )

      if (!newType) return

      newType.onSelected?.(ticket.value)
      currentArticleType.value = newType

      formNode?.find('internal')?.input(newType.internal, false)
    }

    return {
      execution: [
        FormHandlerExecution.Initial,
        FormHandlerExecution.FieldChange,
      ],
      callback: handleArticleType,
    }
  }

  return {
    ticketEditSchema,
    currentArticleType,
    articleTypeHandler,
  }
}
