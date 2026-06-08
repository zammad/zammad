// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineComponent } from 'vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

// Is not properly supported we mock out that dependency as it is not relevant for the test
vi.mock('vue-advanced-cropper', () => {
  const Cropper = defineComponent({
    emits: ['change'],
    mounted() {
      this.$emit('change', {
        canvas: {
          toDataURL() {
            return 'cropped image url'
          },
        },
      })
    },
    template: '<div></div>',
  })

  return {
    Cropper,
  }
})

describe('testing avatar a11y view', () => {
  it('has no accessibility violations', async () => {
    await visitView('/personal-setting/avatar')

    await expect(document.body).toBeAccessible()
  })

  it('has no accessibility violations with upload new avatar by file flyout', async () => {
    const view = await visitView('/personal-setting/avatar')

    const file = new File([], 'test.jpg', { type: 'image/jpeg' })
    await view.events.upload(view.getByTestId('fileUploadInput'), file)

    await waitForNextTick()

    await view.findByRole('complementary', {
      name: 'Crop image',
    })

    await expect(document.body).toBeAccessible()
  })
})
