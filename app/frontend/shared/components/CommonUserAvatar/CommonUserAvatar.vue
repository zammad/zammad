<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import useApplicationStore from '@shared/stores/application'
import { getInitials } from '@shared/utils/formatter'
import CommonAvatar from '../CommonAvatar/CommonAvatar.vue'
import type { AvatarSize } from '../CommonAvatar'
import type { AvatarUser } from './types'

export interface Props {
  entity: AvatarUser
  size?: AvatarSize
  personal?: boolean
}

const props = defineProps<Props>()

const initials = computed(() => {
  const { lastname, firstname, email } = props.entity

  return getInitials(firstname, lastname, email)
})

const colors = [
  'bg-gray',
  'bg-red',
  'bg-yellow',
  'bg-blue',
  'bg-green',
  'bg-pink',
  'bg-orange',
]

const fullName = computed(() => {
  const { lastname, firstname } = props.entity

  return [firstname, lastname].filter(Boolean).join(' ')
})

const colorClass = computed(() => {
  const { email, id } = props.entity

  // TODO ID is mangled by gql, maybe backend should send "isSystem"-like property?
  if (id === '1') return 'bg-white'

  // TODO it's better to use ID, so if someone changes name the color won't change
  const name = [fullName.value, email].filter(Boolean).join('')

  if (!name || name === ' ' || name === '-') return colors[0]
  // get color based on mod of the fullname length
  // so it stays consistent between different interfaces and logins
  return colors[name.length % 5]
})

const sources = ['facebook', 'twitter']

const icon = computed(() => {
  const { id, source } = props.entity
  if (id === '1') return 'logo'
  if (source && sources.includes(source)) return source
  return null
})

const app = useApplicationStore()

const image = computed(() => {
  if (icon.value || !props.entity.image) return null

  // Support the inline data URI as an image source.
  if (props.entity.image.startsWith('data:')) return props.entity.image

  // we're using the REST api here to get the image and to also use the browser image cache
  // TODO: this should be re-evaluated when the desktop app is going to be implemented
  const apiUrl = String(app.config.api_path)
  return `${apiUrl}/users/image/${props.entity.image}`
})

const isVip = computed(() => {
  return !props.personal && props.entity.vip
})

const className = computed(() => {
  const classes = [colorClass.value]

  if (props.entity.outOfOffice) {
    classes.push('opacity-100 grayscale-[70%]')
  } else if (props.entity.active === false) {
    classes.push('opacity-20 grayscale')
  }

  return classes
})
</script>

<template>
  <CommonAvatar
    :initials="initials"
    :size="size"
    :icon="icon"
    :class="className"
    :image="image"
    :vip="isVip"
    :aria-label="`${$t('Avatar')} (${fullName || entity.email || initials})`"
  />
</template>
