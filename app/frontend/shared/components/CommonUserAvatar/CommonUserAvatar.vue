<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { useAppName } from '#shared/composables/useAppName.ts'
import { useAvatarIndicator } from '#shared/composables/useAvatarIndicator.ts'
import { EnumTaskbarApp } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { i18n } from '#shared/i18n.ts'
import { getUserAvatarClasses } from '#shared/initializer/initializeUserAvatarClasses.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import {
  SYSTEM_USER_ID,
  SYSTEM_USER_INTERNAL_ID,
} from '#shared/utils/constants.ts'
import { getInitials } from '#shared/utils/formatter.ts'

import CommonAvatar from '../CommonAvatar/CommonAvatar.vue'

import logo from './assets/logo.svg'

import type { AvatarUserAccess, AvatarUserLive, AvatarUser } from './types.ts'
import type { AvatarSize } from '../CommonAvatar/index.ts'

export interface Props {
  entity: AvatarUser
  size?: AvatarSize
  personal?: boolean
  decorative?: boolean
  initialsOnly?: boolean
  live?: AvatarUserLive
  access?: AvatarUserAccess
  noMuted?: boolean
  noIndicator?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'medium',
})

const initials = computed(() => {
  const { lastname, firstname, email, phone, mobile } = props.entity

  return getInitials(firstname, lastname, email, phone, mobile)
})

const { backgroundColors } = getUserAvatarClasses()

const fullName = computed(() => {
  const { lastname, firstname, fullname } = props.entity

  if (fullname) return fullname

  return [firstname, lastname].filter(Boolean).join(' ')
})

const colorClass = computed(() => {
  const { id } = props.entity

  const internalId = getIdFromGraphQLId(id)

  if (internalId === SYSTEM_USER_INTERNAL_ID) return 'bg-white'

  // get color based on mod of the integer ID
  // so it stays consistent between different interfaces and logins
  return backgroundColors[internalId % (backgroundColors.length - 1)]
})

const sources = ['facebook', 'twitter']

const icon = computed(() => {
  const { source } = props.entity
  if (source && sources.includes(source)) return source
  return null
})

const appName = useAppName()
const application = useApplicationStore()

const image = computed(() => {
  if (icon.value || props.initialsOnly) return null
  if (props.entity.id === SYSTEM_USER_ID) return logo
  if (!props.entity.image) return null

  // Support the inline data URI as an image source.
  if (props.entity.image.startsWith('data:')) return props.entity.image

  // we're using the REST api here to get the image and to also use the browser image cache
  // TODO: this should be re-evaluated when the desktop app is going to be implemented
  const apiUrl = String(application.config.api_path)
  return `${apiUrl}/users/image/${props.entity.image}`
})

const isVip = computed(() => {
  return !props.personal && props.entity.vip
})

const { indicatorIcon, indicatorLabel, indicatorIsIdle } = useAvatarIndicator(
  toRef(props, 'entity'),
  toRef(props, 'personal'),
  toRef(props, 'live'),
  toRef(props, 'access'),
)

const isMuted = computed(() => !props.noMuted && indicatorIsIdle.value)

const className = computed(() => {
  const classes = [colorClass.value]

  if (isMuted.value) {
    classes.push('opacity-60')
  }

  return classes
})

const label = computed(() => {
  let label = i18n.t('Avatar')
  const name = fullName.value || props.entity.email
  if (name) label += ` (${name})`
  if (isVip.value) label += ` (${i18n.t('VIP')})`
  return label
})

const indicator = computed(() => {
  if (appName === EnumTaskbarApp.Mobile || props.noIndicator) return null
  return indicatorIcon.value
})

const indicatorClass = computed(() => {
  if (isMuted.value) return 'fill-stone-200 dark:fill-neutral-500'
  return 'text-black dark:text-white'
})

const indicatorSizes = {
  xs: 'xs',
  small: 'xs',
  medium: 'xs',
  normal: 'tiny',
  large: 'small',
  xl: 'medium',
} as const

const indicatorSize = computed(() => indicatorSizes[props.size])
</script>

<template>
  <div class="relative">
    <CommonAvatar
      :initials="initials"
      :size="size"
      :icon="icon"
      :class="className"
      :image="image"
      :vip-icon="isVip ? 'vip-user' : undefined"
      :decorative="decorative"
      :aria-label="label"
    />
    <div
      v-if="indicator"
      v-tooltip="indicatorLabel"
      class="absolute bottom-0 end-0 flex translate-y-1 items-center justify-center rounded-full bg-blue-200 p-[3px] outline outline-1 -outline-offset-1 outline-neutral-100 ltr:translate-x-2 rtl:-translate-x-2 dark:bg-gray-700 dark:outline-gray-900"
    >
      <CommonIcon
        :class="indicatorClass"
        :label="indicatorLabel"
        :size="indicatorSize"
        :name="indicator"
      />
    </div>
  </div>
</template>
