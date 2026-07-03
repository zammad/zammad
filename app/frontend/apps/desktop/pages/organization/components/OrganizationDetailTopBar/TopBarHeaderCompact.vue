<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'
import { useRouter } from 'vue-router'

import type { Organization } from '#shared/graphql/types.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import OrganizationInfo from '#desktop/components/Organization/OrganizationInfo.vue'

import { useTopBarHeader } from './useTopBarHeader.ts'

interface Props {
  organization: Organization
  organizationDisplayName: string
}

const props = defineProps<Props>()

const router = useRouter()

const { copyOrganizationDisplayNameToClipboard, allowedTopLevelActions, secondLevelActions } =
  useTopBarHeader(toRef(props))
</script>

<template>
  <header class="border-b border-neutral-100 p-2 dark:border-gray-900">
    <div class="mx-auto flex size-full max-w-278">
      <OrganizationInfo :organization="organization" size="small" title-size="large" no-link>
        <template #label-trailing>
          <CommonButton
            v-tooltip="$t('Copy organization display name')"
            variant="secondary"
            icon="files"
            size="small"
            class="ms-1"
            @click="copyOrganizationDisplayNameToClipboard"
          />
        </template>
        <template #actions>
          <div role="toolbar" class="flex items-center gap-1.5 ltr:ml-auto rtl:mr-auto">
            <CommonButton
              v-for="action in allowedTopLevelActions"
              :key="action.key"
              class="aspect-square w-auto! rounded-lg! px-2! outline-offset-0! @3xl:aspect-auto @3xl:rounded-md! @3xl:px-2.5! @3xl:py-1.5!"
              no-truncate
              :prefix-icon="action.icon"
              @click="action?.onClick?.(organization, router)"
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
              :entity="organization"
              no-single-action-mode
              :actions="secondLevelActions"
              placement="end"
              hide-arrow
            />
          </div>
        </template>
      </OrganizationInfo>
    </div>
  </header>
</template>
