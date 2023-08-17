// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Group } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

export default (): DeepPartial<Group> => {
  return {
    id: convertToGraphQLId('Group', 1), // will not generate more than 1 group
    name: 'Users',
  }
}
