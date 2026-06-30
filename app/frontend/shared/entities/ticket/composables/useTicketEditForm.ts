// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { keyBy } from 'lodash-es'
import { computed, nextTick, ref, shallowRef, watch } from 'vue'

import { EXTENSION_NAME as TEXT_TOOL_PLUGIN_NAME } from '#shared/components/Form/fields/FieldEditor/extensions/AiAssistantTextTools.ts'
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
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
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

  const ticketArticleTypeValueLookup = computed(() => keyBy(ticketArticleTypes.value, 'value'))

  const currentArticleType = shallowRef<AppSpecificTicketArticleType>()

  const hasInternalArticle = computed(
    () =>
      (form.value?.values?.article as { internal?: boolean })?.internal ??
      currentArticleType.value?.internal ??
      false,
  )

  const currentSchemaArticleType = computed(() => {
    if (!currentArticleType.value) return undefined

    return {
      ...currentArticleType.value,
      internal: hasInternalArticle.value,
    }
  })

  const recipientContact = computed(() => currentArticleType.value?.options?.recipientContact)
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
      [TEXT_TOOL_PLUGIN_NAME]: {
        groupNodeName: 'group_id',
        ticketNodeName: 'ticket_id',
        customerNodeName: 'customer_id',
        organizationNodeName: 'organization_id',
      },
      ...currentArticleType.value?.editorMeta,
    }
  })

  const articleTypeFields = ['to', 'cc', 'subject', 'body', 'attachments', 'security'] as const

  const articleTypeFieldProps = articleTypeFields.reduce((acc, field) => {
    acc[field] = {
      validation: computed(() => currentArticleType.value?.fields?.[field]?.validation || null),
      required: computed(() => !!currentArticleType.value?.fields?.[field]?.required),
    }

    return acc
  }, {} as TicketArticleTypeFields)

  // Static default values for article type fields for resetting in the different situations.
  const ticketArticleDefaultValues = {
    articleType: undefined,
    internal: undefined,
    inReplyTo: undefined,
    body: '',
  }

  const { isTicketAgent, isTicketCustomer, isTicketEditable } = useTicketView(ticket)

  const isMobileApp = appName === 'mobile'

  // CC starts hidden behind an "Add CC" link on the desktop recipient row (issue #760). It reveals
  //  once the link is clicked, or immediately when CC already has content (e.g. a draft/reply).
  //  Mobile keeps CC always visible.
  const ccLinkActivated = ref(false)

  const showCc = computed(() => {
    if (isMobileApp || ccLinkActivated.value) return true
    const cc = (form.value?.values?.article as { cc?: unknown })?.cc
    return Array.isArray(cc) ? cc.length > 0 : Boolean(cc)
  })

  // Reset the reveal when the reply form is closed (the article type is cleared).
  watch(currentArticleType, (type) => {
    if (!type) ccLinkActivated.value = false
  })

  const application = useApplicationStore()

  const additionalAddArticleNotes = computed(
    () => (application.config.ui_ticket_add_article_hint as Record<string, string>) || {},
  )

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

  // Channel selector: desktop = segmented tab control, mobile = native select. Label is
  //  screen-reader-only (the control is self-explanatory).
  const articleTypeFieldBase = {
    name: 'articleType',
    label: __('Channel'),
    labelSrOnly: true,
    hidden: computed(() => ticketArticleTypes.value.length === 1),
  }

  const articleTypeField = isMobileApp
    ? {
        ...articleTypeFieldBase,
        type: 'select',
        props: {
          classes: { outer: '@md:col-span-1' },
          // Disable auto preselection so the dirty state stays correct.
          noAutoPreselect: true,
          options: ticketArticleTypes,
        },
      }
    : {
        ...articleTypeFieldBase,
        type: 'toggleButtons',
        props: {
          classes: { outer: 'min-w-0' },
          options: ticketArticleTypes,
          size: 'small',
        },
      }

  // Visibility: desktop = compact toggle switch (lock/unlock knob + inline state label),
  //  mobile = native select. Label is screen-reader-only.
  const internalFieldBase = {
    name: 'internal',
    label: __('Visibility'),
    labelSrOnly: true,
    hidden: isTicketCustomer,
  }

  const internalField = isMobileApp
    ? {
        ...internalFieldBase,
        type: 'select',
        props: {
          classes: { outer: '@md:col-span-1' },
          // Disable auto preselection so the dirty state stays correct.
          noAutoPreselect: true,
          options: [
            { value: true, label: __('Internal'), icon: 'lock' },
            { value: false, label: __('Public'), icon: 'unlock' },
          ],
        },
      }
    : {
        ...internalFieldBase,
        type: 'toggle',
        props: {
          // Force a compact "[switch] <state>" LTR row (the default toggle theme reverses the row
          //  and grows the label).
          classes: { outer: 'shrink-0', wrapper: 'flex-row!', label: 'mb-0! grow-0! shrink-0' },
          variants: { true: __('Internal'), false: __('Public') },
          icons: { true: 'lock-fill', false: 'unlock' },
          inlineLabel: true,
          // Value stays `internal` (true = internal), but the switch reads as a visibility control:
          //  its "on" side is Public, so the knob sits left for internal and right for public.
          invertVisual: true,
          size: 'small',
        },
      }

  // Body fields are shared by both platforms; only their layout differs (see `desktopReplyBox` and
  //  `replyBoxFields` below).
  const bodyFields = [
    {
      if: '$currentArticleType.fields.to',
      name: 'to',
      label: __('To'),
      type: 'recipient',
      validation: articleTypeFieldProps.to.validation,
      props: {
        // While CC is hidden the recipient takes the full row; once CC shows they share it.
        classes: computed(() => ({ outer: showCc.value ? '@md:col-span-1' : 'col-span-full' })),
        contact: recipientContact,
        multiple: true,
        // Desktop reveals the CC field via an "Add CC" link on the recipient row (issue #760). The
        //  link disappears once CC is shown or when the article type has no CC field.
        ...(isMobileApp
          ? {}
          : {
              link: computed(() =>
                !showCc.value && currentArticleType.value?.fields?.cc ? '#' : undefined,
              ),
              linkIcon: 'plus',
              linkLabel: __('Add CC'),
              showLinkLabel: true,
              linkSize: 'medium',
              onLinkClick: (e: MouseEvent) => {
                e.preventDefault()
                ccLinkActivated.value = true
                // Move focus to the freshly revealed CC field so it can be filled right away.
                nextTick(() => {
                  const ccFieldId = form.value?.getNodeByName('cc')?.context?.id
                  if (ccFieldId) document.getElementById(ccFieldId)?.focus()
                })
              },
            }),
      },
      required: articleTypeFieldProps.to.required,
    },
    {
      if: '$currentArticleType.fields.cc',
      // Hidden on desktop until revealed via the recipient's "Add CC" link (`showCc` is always true
      //  on mobile). `hidden` keeps the field mounted so any existing value is preserved.
      hidden: computed(() => !showCc.value),
      name: 'cc',
      label: __('CC'),
      type: 'recipient',
      validation: articleTypeFieldProps.cc.validation,
      props: {
        classes: { outer: '@md:col-span-1' },
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
        groupId: computed(() =>
          ticket.value?.group.id ? getIdFromGraphQLId(ticket.value?.group.id) : undefined,
        ),
        organizationId: computed(() => ticket.value?.organization?.internalId),
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
            typeof currentArticleType.value?.fields?.attachments?.multiple === 'boolean'
              ? currentArticleType.value?.fields?.attachments?.multiple
              : true,
          ),
        ),
        allowedFiles: computed(
          () => currentArticleType.value?.fields?.attachments?.allowedFiles || null,
        ),
        accept: computed(() => currentArticleType.value?.fields?.attachments?.accept || null),
      },
      required: articleTypeFieldProps.attachments.required,
    },
  ]

  const articleHint = {
    if: '$existingAdditionalAddArticleNotes() && $getAdditionalAddArticleNote($currentArticleType) !== undefined',
    isLayout: true,
    component: 'CommonAlert',
    props: {
      variant: 'warning',
      class: isMobileApp ? 'col-span-full rounded-b-none' : 'col-span-full', // safe because it's not dynamic
    },
    children: [
      {
        isLayout: true,
        element: 'div',
        attrs: {
          // We convert light weight markup
          // The input is not sanitized and relies on the administrator to provide safe content
          innerHTML: '$markup($t($getAdditionalAddArticleNote($currentArticleType)))',
        },
      },
    ],
  }

  // Desktop reply box = one flex column whose header + body borders form a single outline. The
  //  header border is open at the bottom; the body continues it (public) or replaces it with the
  //  `bg-stripes` indicator (internal). The body's 5px margin/padding offsets the stripe's outward
  //  ring and keeps the content from shifting on toggle.
  const desktopReplyBox = {
    isLayout: true,
    element: 'div',
    attrs: {
      class: {
        if: '$isReplyPinned',
        then: 'col-span-full flex flex-col overflow-hidden',
        else: 'col-span-full flex flex-col',
      },
    },
    children: [
      {
        isLayout: true,
        element: 'div',
        attrs: {
          class:
            'flex flex-wrap items-center gap-x-3 gap-y-2 rounded-t-2xl border border-neutral-300 bg-neutral-50 px-3 py-1.5 ltr:pr-20 rtl:pl-20 dark:border-gray-900 dark:bg-gray-500',
        },
        children: [
          {
            // In the customer view there are no channel/visibility controls, so show a plain "Reply"
            //  title in their place. It doubles as the reply region's heading (carrying the
            //  `aria-labelledby` id), so the panel omits its own sr-only heading for customers to
            //  avoid a duplicate "Reply" (see ArticleReplyPanel.vue).
            isLayout: true,
            if: '$isTicketCustomer',
            element: 'h2',
            attrs: {
              id: 'article-reply-form-title',
              class:
                'flex h-6 items-center text-xs leading-snug text-stone-200 dark:text-neutral-500',
            },
            children: '$t("Reply")',
          },
          articleTypeField,
          internalField,
        ],
      },
      {
        isLayout: true,
        element: 'div',
        attrs: {
          class: {
            if: '$isReplyPinned',
            then: 'rounded-b-2xl border border-t-0 border-neutral-300 bg-neutral-50 dark:border-gray-900 dark:bg-gray-500 overflow-y-auto',
            else: 'rounded-b-2xl border border-t-0 border-neutral-300 bg-neutral-50 dark:border-gray-900 dark:bg-gray-500',
          },
        },
        children: [
          {
            isLayout: true,
            element: 'div',
            attrs: {
              'data-test-id': 'article-reply-internal-indicator',
              class: {
                if: '$currentArticleType.internal',
                then: 'relative z-0 m-[5px] rounded-b-xl bg-stripes outline outline-1 outline-blue-700 before:rounded-b-2xl',
                else: 'rounded-b-2xl bg-neutral-50 p-[5px] dark:bg-gray-500',
              },
            },
            children: [
              {
                isLayout: true,
                element: 'div',
                attrs: {
                  class:
                    '@container grid grid-cols-2 gap-x-3 gap-y-2 rounded-b-xl bg-neutral-50 p-2 dark:bg-gray-500',
                },
                children: [articleHint, ...bodyFields],
              },
            ],
          },
        ],
      },
    ],
  }

  // Mobile stacks the channel, visibility and body fields flat in the form grid; desktop uses the
  //  single connected reply box above.
  const replyBoxFields = isMobileApp
    ? [articleHint, articleTypeField, internalField, ...bodyFields]
    : [desktopReplyBox]

  const articleSchema = {
    // Desktop is handling the condition on top for the teleport.
    if: isMobileApp ? '$newTicketArticleRequested || $newTicketArticlePresent' : undefined,
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
      ...replyBoxFields,
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

    const handleArticleType: FormHandlerFunction = (execution, reactivity, data) => {
      const { formNode, changedField, formUpdaterData } = data
      const { schemaData } = reactivity

      if (
        execution === FormHandlerExecution.Initial &&
        formUpdaterData?.fields.articleType?.value
      ) {
        currentArticleType.value =
          ticketArticleTypeValueLookup.value[formUpdaterData.fields.articleType.value]
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
      const newType = ticketArticleTypeValueLookup.value[changedField?.newValue as string]
      if (!newType) return

      if (!formNode.context?._open) {
        newType.onSelected?.(ticket.value, context, form.value)
      }
      currentArticleType.value = newType

      formNode.find('internal')?.input(newType.internal, false)
    }

    return {
      execution: [FormHandlerExecution.Initial, FormHandlerExecution.FieldChange],
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

  const securityIntegration = computed<boolean>(
    () => (application.config.smime_integration || application.config.pgp_integration) ?? false,
  )

  return {
    ticketSchema,
    articleSchema,
    currentArticleType,
    currentSchemaArticleType,
    ticketArticleTypes,
    ticketArticleDefaultValues,
    securityIntegration,
    isTicketAgent,
    isTicketCustomer,
    isTicketEditable,
    articleTypeHandler: articleTypeChangeHandler,
    articleTypeSelectHandler,
    additionalAddArticleNotes,
  }
}
