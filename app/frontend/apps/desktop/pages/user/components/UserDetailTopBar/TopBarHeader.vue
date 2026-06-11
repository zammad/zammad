<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import { useRouter } from 'vue-router'

import { useCopyToClipboard } from '#shared/composables/useCopyToClipboard.ts'
import type { User } from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonBreadcrumb from '#desktop/components/CommonBreadcrumb/CommonBreadcrumb.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import UserInfo from '#desktop/components/User/UserInfo.vue'
import { initializeActionPlugins } from '#desktop/pages/user/components/UserDetailTopBar/actions/index.ts'

interface Props {
  hideDetails: boolean
  user: User
  userDisplayName: string
}

const props = defineProps<Props>()

const breadcrumbItems = computed(() => [
  { label: __('User') },
  {
    label: props.userDisplayName,
    noOptionLabelTranslation: true,
  },
])

const { copyToClipboard } = useCopyToClipboard()

const config = toRef(useApplicationStore(), 'config')

const copyUserDisplayNameToClipboard = () => {
  copyToClipboard([
    new ClipboardItem({
      'text/plain': props.userDisplayName,
      'text/html': `<a href="${config.value.http_type}://${config.value.fqdn}/desktop/users/${props.user.internalId}">${props.userDisplayName}</a>`,
    }),
  ])
}

const { topLevelActions, secondLevelActions } = initializeActionPlugins()

const { hasPermission } = useSessionStore()

const allowedTopLevelActions = computed(() =>
  topLevelActions.filter(
    (item) =>
      (item.permission ? hasPermission(item.permission) : true) &&
      (item.show ? item.show(props.user) : true),
  ),
)

const router = useRouter()
</script>

<template>
  <header
    class="border-b border-neutral-100 bg-neutral-50 dark:border-gray-900 dark:bg-gray-500"
    :class="hideDetails ? 'p-2' : 'px-5.5 py-3'"
  >
    <template v-if="hideDetails">
      <div class="mx-auto flex w-full max-w-266">
        <UserInfo :user="user" responsive size="small" title-size="large" no-link />
      </div>
    </template>
    <template v-else>
      <!-- h-6 because of ticket detail view has action which add a additional height to the breadcrumbs -->
      <CommonBreadcrumb class="flex h-6" :items="breadcrumbItems" size="small" emphasize-last-item>
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

      <div class="mx-auto mt-3 flex w-full max-w-278">
        <UserInfo
          :user="user"
          size="normal"
          responsive
          has-organization-popover
          title-size="xl"
          title-class="font-medium"
          no-link
        >
          <template #actions>
            <div role="toolbar" class="flex shrink-0 items-center gap-1.5 ltr:ml-auto rtl:mr-auto">
              <CommonButton
                v-for="action in allowedTopLevelActions"
                :key="action.key"
                class="aspect-square w-auto! rounded-lg! px-2! -outline-offset-1! @3xl:aspect-auto @3xl:rounded-md! @3xl:px-2.5! @3xl:py-1.5!"
                no-truncate
                :prefix-icon="action.icon"
                :aria-label="$t(action.label)"
                @click="action?.onClick?.(user, router)"
              >
                <span class="sr-only shrink-0 text-xs! @3xl:not-sr-only">
                  {{ $t(action.label) }}
                </span>
              </CommonButton>
              <CommonActionMenu
                button-size="medium"
                role="presentation"
                class="flex! h-full items-center"
                :custom-menu-button-label="$t('Additional actions')"
                no-single-action-mode
                :actions="secondLevelActions"
                :entity="user"
              />
            </div>
          </template>
        </UserInfo>
      </div>
    </template>
  </header>
</template>
