// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { shallowRef, reactive } from 'vue'

import type { FormRef } from '#shared/components/Form/types.ts'

import type { EmailInboundMetaInformation } from '../types/email-inbound-outbound.ts'
import type { ShallowRef, Ref } from 'vue'

export const useEmailInboundMessagesForm = (
  metaInformationInbound: Ref<Maybe<EmailInboundMetaInformation>>,
) => {
  const formEmailInboundMessages: ShallowRef<FormRef | undefined> = shallowRef()

  const emailInboundMessageSchema = [
    {
      isLayout: true,
      element: 'div',
      attrs: {
        class: 'flex flex-col gap-y-2.5 gap-x-3',
      },
      children: [
        {
          isLayout: true,
          component: 'CommonLabel',
          children:
            '$t("%s email(s) were found in your mailbox. They will all be moved from your mailbox into Zammad.", $metaInformationInbound.contentMessages)',
        },
        {
          isLayout: true,
          component: 'CommonLabel',
          children:
            '$t(\'You can import some of your emails as an "archive", which means that no notifications are sent and the tickets will be in a target state that you define.\')',
        },
        {
          isLayout: true,
          component: 'CommonLabel',
          children:
            '$t("You can find archived emails in Zammad anytime using the search function, like for any other ticket.")',
        },
        {
          name: 'archive',
          label: __('Archive emails'),
          type: 'toggle',
          value: true,
          props: {
            variants: {
              true: __('yes'),
              false: __('no'),
            },
          },
        },
        {
          name: 'archive_before',
          if: '$values.archive',
          type: 'datetime',
          label: __('Archive cut-off time'),
          required: true,
          help: __(
            'Emails before the cut-off time are imported as archived tickets. Emails after the cut-off time are imported as regular tickets.',
          ),
        },
        {
          name: 'archive_state_id',
          if: '$values.archive',
          label: __('Archive ticket target state'),
          type: 'select',
        },
      ],
    },
  ]

  const emailInboundMessageSchemaData = reactive({
    metaInformationInbound,
  })

  return {
    formEmailInboundMessages,
    emailInboundMessageSchema,
    emailInboundMessageSchemaData,
  }
}
