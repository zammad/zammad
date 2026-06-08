// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormUpdaterResult } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<FormUpdaterResult> => {
  return {
    fields: {
      name: {
        show: true,
        hidden: false,
        disabled: false,
        required: true,
      },
      shared: {
        show: true,
        hidden: false,
        rejectNonExistentValues: true,
        clearable: false,
        options: [
          {
            value: 'true',
            label: 'yes',
          },
          {
            value: 'false',
            label: 'no',
          },
        ],
        disabled: false,
        required: true,
      },
      domain_assignment: {
        show: true,
        hidden: false,
        rejectNonExistentValues: true,
        clearable: false,
        options: [
          {
            value: 'true',
            label: 'yes',
          },
          {
            value: 'false',
            label: 'no',
          },
        ],
        disabled: false,
        required: true,
      },
      domain: {
        show: true,
        hidden: false,
        disabled: false,
        required: false,
      },
      vip: {
        show: true,
        hidden: false,
        rejectNonExistentValues: true,
        clearable: false,
        options: [
          {
            value: 'false',
            label: 'no',
          },
          {
            value: 'true',
            label: 'yes',
          },
        ],
        disabled: false,
        required: false,
      },
      note: {
        show: true,
        hidden: false,
        disabled: false,
        required: false,
      },
      active: {
        show: true,
        hidden: false,
        disabled: false,
        required: true,
      },
    },
    flags: {},
  }
}
