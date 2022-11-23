<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import CommonButtonGroup from '@mobile/components/CommonButtonGroup/CommonButtonGroup.vue'
import type { CommonButtonOption } from '@mobile/components/CommonButtonGroup/types'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuLink from '@mobile/components/CommonSectionMenu/CommonSectionMenuLink.vue'
import CommonUserAvatar from '@shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import CommonOrganizationAvatar from '@shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import { closeDialog } from '@shared/composables/useDialog'

interface Props {
  name: string
}

defineProps<Props>()

const topButtons: CommonButtonOption[] = [
  {
    label: __('Merge tickets'),
    icon: 'mobile-merge',
    onAction() {
      console.log('open merge tickets autocomplete')
    },
  },
  {
    label: __('Subscribe'),
    icon: 'mobile-notification-subscribed',
    value: 'subscribe',
    onAction() {
      console.log('subscribe for a ticket')
    },
  },
  {
    label: __('Ticket info'),
    icon: 'mobile-info',
    onAction() {
      console.log('show ticket info')
    },
  },
]
</script>

<template>
  <CommonDialog :name="name" :label="__('Ticket actions')">
    <template #before-label>
      <!-- TODO what is its purpose? -->
      <button type="button" class="text-white" @click="closeDialog(name)">
        Cancel
      </button>
    </template>
    <div class="w-full px-3">
      <CommonButtonGroup class="py-6" mode="full" :options="topButtons" />
      <CommonSectionMenu>
        <CommonSectionMenuLink
          :label="__('Execute configured macros')"
          icon="mobile-macros"
          icon-bg="bg-green"
        />
      </CommonSectionMenu>
      <CommonSectionMenu>
        <CommonSectionMenuLink
          :label="__('History')"
          icon="mobile-history"
          icon-bg="bg-gray"
        />
      </CommonSectionMenu>
      <CommonSectionMenu>
        <CommonSectionMenuLink :label="__('Edit customer')">
          <template #icon>
            <CommonUserAvatar :entity="{ id: '1' }" size="small" />
          </template>
        </CommonSectionMenuLink>
        <CommonSectionMenuLink :label="__('Edit organization')">
          <template #icon>
            <CommonOrganizationAvatar
              :entity="{ name: 'Zammad', active: true }"
              size="small"
            />
          </template>
        </CommonSectionMenuLink>
      </CommonSectionMenu>
      <CommonSectionMenu>
        <CommonSectionMenuLink
          :label="__('Add tags')"
          icon="mobile-tag"
          icon-bg="bg-pink"
        />
      </CommonSectionMenu>
    </div>
  </CommonDialog>
</template>
