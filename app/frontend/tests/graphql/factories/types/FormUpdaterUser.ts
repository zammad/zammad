// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormUpdaterResult } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<FormUpdaterResult> => {
  return {
    fields: {
      role_ids: {
        initialValue: null,
        options: [
          {
            value: 1,
            label: 'Admin',
            description: 'To configure your system.',
          },
          {
            value: 2,
            label: 'Agent',
            description: 'To work on Tickets.',
          },
          {
            value: 3,
            label: 'Customer',
            description: 'People who create Tickets ask for help.',
          },
        ],
        show: true,
        hidden: false,
        disabled: false,
        required: false,
      },
      group_ids: {
        initialValue: null,
        options: [
          {
            value: 1,
            label: 'Users',
          },
          {
            value: 2,
            label: 'some group1',
          },
        ],
        show: false,
        hidden: false,
        disabled: false,
        required: false,
      },
      firstname: {
        show: true,
        hidden: false,
        disabled: false,
        required: false,
      },
      lastname: {
        show: true,
        hidden: false,
        disabled: false,
        required: false,
      },
      email: {
        show: true,
        hidden: false,
        disabled: false,
        required: false,
      },
      web: {
        show: true,
        hidden: false,
        disabled: false,
        required: false,
      },
      phone: {
        show: true,
        hidden: false,
        disabled: false,
        required: false,
      },
      mobile: {
        show: true,
        hidden: false,
        disabled: false,
        required: false,
      },
      fax: {
        show: true,
        hidden: false,
        disabled: false,
        required: false,
      },
      organization_id: {
        show: true,
        hidden: false,
        disabled: false,
        required: false,
      },
      organization_ids: {
        show: true,
        hidden: false,
        disabled: false,
        required: false,
      },
      department: {
        show: true,
        hidden: false,
        disabled: false,
        required: false,
      },
      address: {
        show: true,
        hidden: false,
        disabled: false,
        required: false,
      },
      password: {
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
        required: false,
      },
    },
    flags: {},
  }
}
