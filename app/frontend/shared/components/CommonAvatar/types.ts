// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export type AvatarSize = 'xs' | 'small' | 'medium' | 'normal' | 'large' | 'xl'

// Maps each avatar size to the next smaller one. Used by the `responsive` flag
// to scale an avatar (and its icon/vip/text) down by one step below the @3xl
// container breakpoint.
export const nextSmallerAvatarSize: Record<AvatarSize, AvatarSize> = {
  xs: 'xs',
  small: 'xs',
  medium: 'small',
  normal: 'medium',
  large: 'normal',
  xl: 'large',
}

export interface AvatarClassMap {
  base: string
  vipUser: string
  vipOrganization: string
}
