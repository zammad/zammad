<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonAvatar from '@shared/components/CommonAvatar/CommonAvatar.vue'
import type { AvatarSize } from '@shared/components/CommonAvatar'
import type { AvatarUser } from '@shared/components/CommonUserAvatar/types'
import { getInitials } from '@shared/utils/formatter'
import { computed } from 'vue'

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

const colorClass = computed(() => {
  const { lastname, firstname, email, id } = props.entity

  if (id === '1') return 'bg-white'

  const name = [firstname, lastname, email].filter(Boolean).join('')

  if (!name) return colors[0]
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

const image = computed(() => {
  if (icon.value || !props.entity.image) return null
  // TODO see how we will do this when API will be in Graphql Context
  const apiUrl = '/api/v1'
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
    v-bind:initials="initials"
    v-bind:size="size"
    v-bind:icon="icon"
    v-bind:class="className"
    v-bind:image="image"
    v-bind:vip="isVip"
  />
</template>
