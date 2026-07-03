<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import { useRouter } from 'vue-router'

import type { Organization } from '#shared/graphql/types.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonBreadcrumb from '#desktop/components/CommonBreadcrumb/CommonBreadcrumb.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import OrganizationInfo from '#desktop/components/Organization/OrganizationInfo.vue'

import { useTopBarHeader } from './useTopBarHeader.ts'

export interface Props {
  organization: Organization
  organizationDisplayName: string
}

const props = defineProps<Props>()

const router = useRouter()

const breadcrumbItems = computed(() => [
  // TODO: Adjust breadcrumbs when the navigational mechanism is in place.
  {
    label: __('Organization'),
  },
  {
    label: props.organizationDisplayName,
    noOptionLabelTranslation: true,
  },
])

const { copyOrganizationDisplayNameToClipboard, allowedTopLevelActions, secondLevelActions } =
  useTopBarHeader(toRef(props))
</script>

<template>
  <header class="border-b border-neutral-100 px-5.5 py-3 dark:border-gray-900">
    <!-- h-6 because of ticket detail view has action which add a additional height to the breadcrumbs -->
    <CommonBreadcrumb class="flex h-6" :items="breadcrumbItems" size="small" emphasize-last-item>
      <template #trailing>
        <CommonButton
          v-if="organizationDisplayName"
          v-tooltip="$t('Copy organization display name')"
          variant="secondary"
          icon="files"
          size="small"
          class="ms-1"
          @click="copyOrganizationDisplayNameToClipboard"
        />
      </template>
    </CommonBreadcrumb>

    <div class="mx-auto mt-3 flex w-full max-w-278">
      <OrganizationInfo
        :organization="organization"
        size="normal"
        responsive
        title-size="xl"
        title-class="font-medium"
        no-link
      >
        <template #actions>
          <div role="toolbar" class="flex shrink-0 items-center gap-1.5 ltr:ml-auto rtl:mr-auto">
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
            />
          </div>
        </template>
      </OrganizationInfo>
    </div>
  </header>
</template>
