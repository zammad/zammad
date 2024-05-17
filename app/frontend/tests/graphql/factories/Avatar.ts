// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'

import type { Avatar } from '#shared/graphql/types.ts'

export default (): Partial<Avatar> => {
  return {
    imageFull: faker.image.dataUri(),
    imageResize: faker.image.dataUri(),
  }
}
