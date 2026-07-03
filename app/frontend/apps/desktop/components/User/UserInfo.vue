<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import type { Sizes } from '#shared/components/CommonLabel/types.ts'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type { AvatarUserLive } from '#shared/components/CommonUserAvatar/types.ts'
import type { AvatarUser } from '#shared/components/CommonUserAvatar/types.ts'
import { useOrganizationEntity } from '#shared/entities/organization/composables/useOrganizationEntity.ts'
import { useUserEntity } from '#shared/entities/user/composables/useUserEntity.ts'
import type { Organization, User } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import OrganizationPopoverWithTrigger from '#desktop/components/Organization/OrganizationPopoverWithTrigger.vue'

interface Props {
  user: Partial<User>
  live?: AvatarUserLive
  responsive?: boolean
  size?: 'small' | 'normal'
  dense?: boolean
  noLink?: boolean
  hasOrganizationPopover?: boolean
  titleSize?: Sizes
  titleClass?: string
}

const props = withDefaults(defineProps<Props>(), {
  size: 'normal',
})

const avatarComponent = computed(() => (props.noLink || props.dense ? 'div' : 'CommonLink'))
const nameComponent = computed(() => (props.noLink && !props.dense ? 'div' : 'CommonLink'))

const labelSize = computed(() => (props.size === 'normal' ? 'large' : 'medium'))

const { userDisplayName } = useUserEntity(toRef(props, 'user'))

const organization = computed(() => props.user.organization as Partial<Organization>)

const { organizationDisplayName } = useOrganizationEntity(organization)
</script>

<template>
  <div class="flex w-full items-center" :class="{ 'gap-2': !titleSize, 'gap-3': titleSize }">
    <component
      :is="avatarComponent"
      :class="{
        'hover:rounded-full hover:no-underline! hover:outline-1 hover:outline-blue-600 focus-visible:rounded-full! hover:dark:outline-blue-900':
          !dense && !noLink,
      }"
      :link="!dense && !noLink ? `/users/${getIdFromGraphQLId(user.id!)}` : undefined"
    >
      <CommonUserAvatar
        v-if="user"
        :entity="user as AvatarUser"
        :live="live"
        :responsive="responsive"
        :size="size"
      />
    </component>
    <!-- max-w-5xl - p-3 =  max-w-244 because section in @see UserDetailViewContent section -->
    <!-- So we are in the same constraint -->
    <div class="flex w-full max-w-244 justify-between">
      <div class="flex flex-col justify-center gap-px">
        <component
          :is="nameComponent"
          v-if="dense"
          class="text-sm leading-snug"
          :class="{ group: !noLink }"
          :link="!noLink ? `/users/${getIdFromGraphQLId(user.id!)}` : undefined"
        >
          <CommonLabel
            :class="{
              [`${titleClass}`]: titleClass,
              'text-blue-800! group-hover:text-blue-850! group-hover:dark:text-blue-600!': !noLink,
            }"
            class="line-clamp-2! break-word"
            :size="titleSize ? titleSize : labelSize"
          >
            {{ userDisplayName }}
          </CommonLabel>
        </component>
        <div v-else class="flex items-center">
          <CommonLabel
            :size="titleSize ? titleSize : labelSize"
            class="line-clamp-2! break-all text-gray-300! dark:text-neutral-400!"
            :class="titleClass"
          >
            {{ userDisplayName }}
          </CommonLabel>
          <slot name="label-trailing" />
        </div>

        <OrganizationPopoverWithTrigger
          v-if="!dense && user.organization && hasOrganizationPopover"
          class="rounded-sm outline-offset-1 focus-visible:outline-2!"
          :popover-config="{ orientation: 'left' }"
          :organization="user.organization"
          z-index="52"
          trigger-link-class="self-start"
          trigger-link-active-class="outline-2! outline-blue-800! hover:outline-blue-800!"
        >
          <CommonLabel
            class="line-clamp-2! break-word text-blue-800! hover:text-blue-850! hover:dark:text-blue-600!"
            :size="labelSize"
          >
            {{ organizationDisplayName }}
          </CommonLabel>
        </OrganizationPopoverWithTrigger>
        <CommonLink
          v-else-if="!dense && user.organization"
          :link="`/organizations/${user.organization?.internalId}`"
        >
          <CommonLabel
            class="line-clamp-2! break-word text-blue-800! hover:text-blue-850! hover:dark:text-blue-600!"
            :size="labelSize"
          >
            {{ organizationDisplayName }}
          </CommonLabel>
        </CommonLink>
      </div>
      <slot name="actions" />
    </div>
  </div>
</template>
