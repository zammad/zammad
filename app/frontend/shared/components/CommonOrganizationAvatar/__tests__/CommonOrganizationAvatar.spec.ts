// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import CommonOrganizationAvatar from '../CommonOrganizationAvatar.vue'

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

    expect(view.getByIconName('mobile-organization')).toBeInTheDocument()

    await view.rerender({
      entity: {
        name: 'Zammad Foundation',
        active: false,
      },
    })

    expect(
      view.getByIconName('mobile-inactive-organization'),
    ).toBeInTheDocument()
  })
})
