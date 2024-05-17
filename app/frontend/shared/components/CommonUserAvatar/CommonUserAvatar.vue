<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useDateFormat } from '@vueuse/shared'
import { computed } from 'vue'

import { useReactiveNow } from '#shared/composables/useReactiveNow.ts'
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

import type { AvatarUser } from './types.ts'
import type { AvatarSize } from '../CommonAvatar/index.ts'

export interface Props {
  entity: AvatarUser
  size?: AvatarSize
  personal?: boolean
  decorative?: boolean
  initialsOnly?: boolean
}

const props = defineProps<Props>()

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

const currentDate = useReactiveNow()

const isOutOfOffice = computed(() => {
  if (
    props.entity.outOfOffice &&
    props.entity.outOfOfficeStartAt &&
    props.entity.outOfOfficeEndAt
  ) {
    const today = useDateFormat(currentDate.value, 'YYYY-MM-DD')
    const startDate = props.entity?.outOfOfficeStartAt
    const endDate = props.entity?.outOfOfficeEndAt

    return startDate <= today.value && endDate >= today.value // Today is between start and end date
  }
  return false
})

const className = computed(() => {
  const classes = [colorClass.value]

  if (isOutOfOffice.value) {
    classes.push('opacity-100 grayscale-[70%]')
  } else if (props.entity.active === false) {
    classes.push('opacity-20 grayscale')
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
</script>

<template>
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
</template>
