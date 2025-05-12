<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { EnumLinkType, type LinkListQuery } from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import type { ActionFooterOptions } from '#desktop/components/CommonFlyout/types.ts'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import TicketRelationAndRecentLists from '#desktop/pages/ticket/components/TicketDetailView/TicketRelationAndRecentLists/TicketRelationAndRecentLists.vue'
import { useObjectLinkTypes } from '#desktop/pages/ticket/composables/useObjectLinkTypes.ts'
import { useTargetTicketOptions } from '#desktop/pages/ticket/composables/useTargetTicketOptions.ts'
import { useLinkAddMutation } from '#desktop/pages/ticket/graphql/mutations/linkAdd.api.ts'
import { LinkListDocument } from '#desktop/pages/ticket/graphql/queries/linkList.api.ts'

interface Props {
  sourceTicket: TicketById
}
const props = defineProps<Props>()

const sourceTicket = toRef(props, 'sourceTicket')

const { form, updateFieldValues, onChangedField } = useForm()

const { formListTargetTicketOptions, targetTicketId, handleTicketClick } =
  useTargetTicketOptions(onChangedField, updateFieldValues)

const { linkTypes } = useObjectLinkTypes()

const linkFormSchema = [
  {
    isLayout: true,
    element: 'div',
    attrs: {
      class: 'grid gap-y-2.5 gap-x-3',
    },
    children: [
      {
        name: 'targetTicketId',
        type: 'ticket',
        label: __('Link ticket'),
        exceptTicketInternalId: sourceTicket.value.internalId,
        options: formListTargetTicketOptions,
        clearable: true,
        required: true,
      },
      {
        name: 'linkType',
        type: 'select',
        label: __('Link type'),
        options: linkTypes,
      },
    ],
  },
]

const initialValues = {
  linkType: EnumLinkType.Normal,
}

const footerActionOptions = computed<ActionFooterOptions>(() => ({
  actionButton: {
    variant: 'submit',
    type: 'submit',
  },
  actionLabel: __('Link'),
}))

const { notify } = useNotifications()

const addLink = async (
  formData: FormSubmitData<{
    targetTicketId: string
    linkType: EnumLinkType
  }>,
) => {
  const addLinkMutation = new MutationHandler(
    useLinkAddMutation({
      variables: {
        input: {
          // Don't ask me why, but the sourceId and targetId are swapped to be consistent with the old UI.
          sourceId: formData.targetTicketId,
          targetId: sourceTicket.value.id,
          type: formData.linkType,
        },
      },
      update: (cache, { data }) => {
        if (!data) return

        const { linkAdd } = data
        if (!linkAdd?.link) return

        const { link: newLink } = linkAdd

        const variables = {
          objectId: sourceTicket.value.id,
          targetType: 'Ticket',
        }

        let existingLinks = cache.readQuery<LinkListQuery>({
          query: LinkListDocument,
          variables,
        })

        const newIdPresent = existingLinks?.linkList?.find((link) => {
          return link.item.id === newLink.item.id && link.type === newLink.type
        })
        if (newIdPresent) return

        existingLinks = {
          ...existingLinks,
          linkList: [...(existingLinks?.linkList || []), newLink],
        }

        cache.writeQuery({
          query: LinkListDocument,
          data: existingLinks,
          variables,
        })
      },
    }),
    {
      errorShowNotification: false,
    },
  )

  return addLinkMutation.send().then((data) => {
    if (data?.linkAdd) {
      return () => {
        notify({
          type: NotificationTypes.Success,
          message: __('Link added successfully'),
        })

        closeFlyout('ticket-link')
      }
    }
  })
}
</script>

<template>
  <CommonFlyout
    :header-title="__('Link Tickets')"
    header-icon="link"
    name="ticket-link"
    size="large"
    no-close-on-action
    :form="form"
    :footer-action-options="footerActionOptions"
  >
    <div class="space-y-6">
      <Form
        ref="form"
        :schema="linkFormSchema"
        :initial-values="initialValues"
        should-autofocus
        @submit="
          addLink(
            $event as FormSubmitData<{
              targetTicketId: string
              linkType: EnumLinkType
            }>,
          )
        "
      />

      <TicketRelationAndRecentLists
        :customer-id="sourceTicket.customer.id"
        :internal-ticket-id="sourceTicket.internalId"
        :selected-ticket-id="targetTicketId"
        @click-ticket="handleTicketClick"
      />
    </div>
  </CommonFlyout>
</template>
