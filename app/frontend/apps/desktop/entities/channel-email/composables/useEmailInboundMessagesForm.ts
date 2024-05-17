// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { shallowRef, reactive } from 'vue'

import type { FormRef } from '#shared/components/Form/types.ts'
import { i18n } from '#shared/i18n/index.ts'
import { markup } from '#shared/utils/markup.ts'

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
          if: '$metaInformationInbound.archivePossible === true',
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
                '$t(\'In addition, we have found emails in your mailbox that are older than %s weeks. You can import such emails as an "archive", which means that no notifications are sent and the tickets have the status "closed". However, you can find them in Zammad anytime using the search function.\', $metaInformationInbound.archiveWeekRange)',
            },
            {
              isLayout: true,
              component: 'CommonLabel',
              children:
                '$t("Should the emails from this mailbox be imported as an archive or as regular emails?")',
            },
            {
              isLayout: true,
              element: 'ul',
              attrs: {
                class:
                  'text-sm dark:text-neutral-400 text-gray-100 gap-1 list-disc ltr:ml-5 rtl:mr-5',
              },
              children: [
                {
                  isLayout: true,
                  element: 'li',
                  attrs: {
                    innerHTML: markup(
                      i18n.t(
                        'Import as archive: |No notifications are sent|, the |tickets are closed|, and original timestamps are used. You can still find them in Zammad using the search.',
                      ),
                    ),
                  },
                  children: '',
                },
                {
                  isLayout: true,
                  element: 'li',
                  attrs: {
                    innerHTML: markup(
                      i18n.t(
                        'Import as regular: |Notifications are sent| and the |tickets are open| - you can find the tickets in the overview of open tickets.',
                      ),
                    ),
                  },
                  children: '',
                },
              ],
            },
            {
              if: '$metaInformationInbound.archivePossible === true',
              name: 'importAs',
              label: __('Email import mode'),
              type: 'select',
              value: 'false',
              options: [
                {
                  value: 'true',
                  label: __('Import as archive'),
                },
                {
                  value: 'false',
                  label: __('Import as regular'),
                },
              ],
            },
          ],
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
