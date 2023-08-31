// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { StoredFile } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'
import { faker } from '@faker-js/faker'

export default (): DeepPartial<StoredFile> => {
  const randomFile = faker.helpers.arrayElement([
    { name: 'file1.png', type: 'image/png' },
    { name: 'file2.jpg', type: 'image/jpeg' },
    { name: 'file3.gif', type: 'image/gif' },
    { name: 'file4.pdf', type: 'application/pdf' },
  ])
  return {
    name: randomFile.name,
    type: randomFile.type,
    preferences: {
      'original-format': faker.datatype.boolean() as any,
    },
  }
}
