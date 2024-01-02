// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { LinkClassMap } from '#shared/components/CommonLink/types.ts'

// Provide your own map with the following keys, the values given here are just examples.
let linkClasses: LinkClassMap = {
  base: 'common-link',
}

export const initializeLinkClasses = (classes: LinkClassMap) => {
  linkClasses = classes
}

export const getLinkClasses = () => linkClasses
