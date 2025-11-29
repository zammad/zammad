<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed, ref, toRef, type Ref } from 'vue'

import { useCopyToClipboard } from '#shared/composables/useCopyToClipboard.ts'
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import type { User } from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import CommonBreadcrumb from '#desktop/components/CommonBreadcrumb/CommonBreadcrumb.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import UserInfo from '#desktop/components/User/UserInfo.vue'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'

interface Props {
  user: User
  userDisplayName: string
  contentContainerElement: HTMLElement | null
}

const props = defineProps<Props>()

const breadcrumbItems = computed(() => [
  // TODO: Adjust breadcrumbs when the navigational mechanism is in place.
  {
    label: __('User'),
  },
  {
    label: props.userDisplayName,
    noOptionLabelTranslation: true,
  },
])

const { copyToClipboard } = useCopyToClipboard()

const { config } = storeToRefs(useApplicationStore())

const copyUserDisplayNameToClipboard = () => {
  copyToClipboard([
    new ClipboardItem({
      'text/plain': props.userDisplayName,
      'text/html': `<a href="${config.value.http_type}://${config.value.fqdn}/desktop/users/${props.user.internalId}">${props.userDisplayName}</a>`,
    }),
  ])
}

const { y } = useElementScroll(toRef(props, 'contentContainerElement') as Ref<HTMLDivElement>)

const isHovering = ref(false)

const { isTouchDevice } = useTouchDevice()

const events = computed(() => {
  if (isTouchDevice.value)
    return {
      touchstart() {
        isHovering.value = true
      },
      touchend() {
        isHovering.value = false
      },
    }

  return {
    mouseenter() {
      isHovering.value = true
    },
    mouseleave() {
      isHovering.value = false
    },
  }
})
</script>

<template>
  <header
    class="absolute top-0 left-0 right-0 z-30 w-full h-17 border-b border-neutral-100 bg-neutral-50 p-3 dark:border-gray-900 dark:bg-gray-500"
    :style="{
      transform: `translateY(${y - (137 + 70) > 0 ? 0 : y - (137 + 70)}px)`,
    }"
    aria-hidden="true"
    v-on="events"
  >
    <div class="flex mx-auto w-full max-w-266">
      <UserInfo :user="user" size="small" title-size="large" no-link />
    </div>
  </header>
  <header
    data-test-id="user-detail-top-bar"
    class="sticky z-30 h-34 border-b border-neutral-100 bg-neutral-50 p-3 dark:border-gray-900 dark:bg-gray-500"
    :class="{
      'transition-[top]': isHovering,
    }"
    :style="{
      top: isHovering ? '0px' : y < 137 ? `-${y}px` : '-137px',
    }"
    v-on="events"
  >
    <CommonBreadcrumb :items="breadcrumbItems" size="small" emphasize-last-item>
      <template #trailing>
        <CommonButton
          v-if="userDisplayName"
          v-tooltip="$t('Copy user display name')"
          variant="secondary"
          icon="files"
          size="small"
          class="ms-1"
          @click="copyUserDisplayNameToClipboard"
        />
      </template>
    </CommonBreadcrumb>
    <div class="flex mx-auto mt-3 w-full max-w-278 h-21">
      <UserInfo
        :user="user"
        size="normal"
        has-organization-popover
        title-size="xl"
        title-class="font-medium"
        no-link
      />
    </div>
  </header>
</template>
