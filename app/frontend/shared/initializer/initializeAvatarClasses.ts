// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { AvatarClassMap } from '#shared/components/CommonAvatar/types.ts'

// Provide your own map with the following keys, the values given here are just examples.
let avatarClasses: AvatarClassMap = {
  base: 'common-avatar-base',
  vipUser: 'common-avatar-vip-user',
  vipOrganization: 'common-avatar-vip-organization',
}

export const initializeAvatarClasses = (classes: AvatarClassMap) => {
  avatarClasses = classes
}

export const getAvatarClasses = () => avatarClasses
