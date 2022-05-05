// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import CommonOrganizationAvatar from '@shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import { renderComponent } from '@tests/support/components'

describe('CommonOrganizationAvatar', () => {
  it('renders avatar', async () => {
    const view = renderComponent(CommonOrganizationAvatar, {
      props: {
        entity: {
          name: 'Zammad Foundation',
          active: true,
        },
      },
    })

    expect(view.getIconByName('organization')).toBeInTheDocument()

    await view.rerender({
      entity: {
        name: 'Zammad Foundation',
        active: false,
      },
    })

    expect(view.getIconByName('inactive-organization')).toBeInTheDocument()
  })
})
