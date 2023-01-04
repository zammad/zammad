// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import ArticleMetadataAddress from '../ArticleMetadataAddress.vue'

describe('displaying contact address in metadata', () => {
  it('displays raw data, if no emails is provided', () => {
    const view = renderComponent(ArticleMetadataAddress, {
      props: {
        label: 'Label',
        address: {
          raw: 'some-email',
        },
      },
    })

    expect(view.getByRole('region', { name: 'Label' })).toHaveTextContent(
      /some-email/,
    )
  })

  it('displays parsed data, if exists', () => {
    const view = renderComponent(ArticleMetadataAddress, {
      props: {
        label: 'Label',
        address: {
          raw: 'some-email',
          parsed: [
            { name: 'Nicole', emailAddress: 'addres@mail.io' },
            { name: 'Brown', emailAddress: 'brown@mail.io' },
            { name: 'Rose' },
          ],
        },
      },
    })

    const [nicole, brown, rose] = view.getAllByTestId('metadataAddress')

    expect(nicole).toHaveTextContent('Nicole')
    expect(nicole).toHaveTextContent('addres@mail.io')

    expect(brown).toHaveTextContent('Brown')
    expect(brown).toHaveTextContent('brown@mail.io')

    expect(rose).toHaveTextContent('Rose')
  })
})
