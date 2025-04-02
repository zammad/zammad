<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import type { EnumLinkType, LinkListQuery } from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonDivider from '#desktop/components/CommonDivider/CommonDivider.vue'
import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonTicketLabel from '#desktop/components/CommonTicketLabel/CommonTicketLabel.vue'
import { useObjectLinks } from '#desktop/pages/ticket/composables/useObjectLinks.ts'
import { useLinkRemoveMutation } from '#desktop/pages/ticket/graphql/mutations/linkRemove.api.ts'
import { LinkListDocument } from '#desktop/pages/ticket/graphql/queries/linkList.api.ts'

export interface Props {
  ticket?: TicketById
  isTicketEditable?: boolean
}

const props = defineProps<Props>()

const ticketReactive = toRef(props, 'ticket')

const { hasLinks, linkTypesWithLinks, linkListIsLoading } = useObjectLinks(
  ticketReactive,
  'Ticket',
)

const { isTouchDevice } = useTouchDevice()

const { waitForVariantConfirmation } = useConfirmation()

const { notify } = useNotifications()

const deleteLink = async (targetId: string, type: string) => {
  if (!ticketReactive.value) return

  const deleteLinkMutation = new MutationHandler(
    useLinkRemoveMutation({
      variables: {
        input: {
          // Don't ask me why, but the sourceId and targetId are swapped to be consistent with the old UI.
          sourceId: targetId,
          targetId: ticketReactive.value.id,
          type: type as EnumLinkType,
        },
      },
      update(cache) {
        const variables = {
          objectId: ticketReactive.value?.id,
          targetType: 'Ticket',
        }

        const existingLinks = cache.readQuery<LinkListQuery>({
          query: LinkListDocument,
          variables,
        })
        if (!existingLinks) return

        cache.writeQuery({
          query: LinkListDocument,
          data: {
            linkList: existingLinks?.linkList?.filter(
              (link) => !(link.item.id === targetId && link.type === type),
            ),
          },
          variables,
        })
      },
    }),
    {
      errorShowNotification: false,
    },
  )

  deleteLinkMutation.send().then((data) => {
    if (data?.linkRemove?.success) {
      notify({
        type: NotificationTypes.Success,
        message: __('Link removed successfully'),
      })
    }
  })
}

const confirmDeleteLink = async (targetId: string, type: string) => {
  const confirmed = await waitForVariantConfirmation('delete')

  if (confirmed) deleteLink(targetId, type)
}

const linkFlyout = useFlyout({
  name: 'ticket-link',
  component: () => import('../../../TicketLinksFlyout.vue'),
})

const openLinkFlyout = () => {
  linkFlyout.open({
    sourceTicket: ticketReactive,
  })
}

defineExpose({ hasLinks })
</script>

<template>
  <CommonLoader :loading="linkListIsLoading">
    <div class="flex flex-col gap-2">
      <div
        v-if="hasLinks"
        class="flex w-full flex-col rounded-lg bg-blue-200 px-2.5 dark:bg-gray-700"
      >
        <div v-for="(type, idx) in linkTypesWithLinks" :key="type.id">
          <CommonLabel
            size="small"
            class="text-stone-200! dark:text-neutral-500!"
          >
            {{ $t(type.label) }}
          </CommonLabel>

          <div
            v-for="link in type.links"
            :key="link.item.id"
            class="group/link relative flex items-center"
          >
            <CommonTicketLabel
              class="h-12 items-center!"
              :ticket="link.item as TicketById"
              :classes="{ indicator: 'mt-0!', label: 'mt-0! line-clamp-1!' }"
            />
            <CommonButton
              v-if="isTicketEditable"
              :aria-label="$t('Delete this link')"
              :class="{ 'opacity-0 transition-opacity': !isTouchDevice }"
              class="text-white group-hover/link:opacity-100 focus:opacity-100"
              icon="x-lg"
              size="small"
              variant="remove"
              @click.stop="confirmDeleteLink(link.item.id, link.type)"
            />
          </div>

          <CommonDivider v-if="idx !== linkTypesWithLinks.length - 1" />
        </div>
      </div>

      <CommonLabel v-else size="small">
        {{ $t('No links added yet.') }}
      </CommonLabel>

      <CommonButton
        v-if="isTicketEditable"
        v-tooltip="$t('Add link')"
        size="medium"
        class="self-end"
        icon="plus-square-fill"
        @click="openLinkFlyout"
      />
    </div>
  </CommonLoader>
</template>
