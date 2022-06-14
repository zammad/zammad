// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { ExtendedRenderResult } from '@tests/support/components'
import { visitView } from '@tests/support/components/visitView'
import { mockAccount } from '@tests/support/mock-account'
import { defineComponent } from 'vue'

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

// TODO should check API in the future, made a separate function,
// so it will be easier to migrate
const checkResult = async (view: ExtendedRenderResult, state: any) => {
  vi.spyOn(console, 'log').mockImplementation(() => ({}))

  await view.events.click(view.getByText('Save'))

  expect(console.log).toHaveBeenCalledWith('save image', state)
}

describe('editing avatar', () => {
  beforeEach(() => {
    mockAccount({
      firstname: 'John',
    })
  })

  afterEach(() => {
    vi.mocked(console.log).mockRestore()
  })

  it('can remove avatar', async () => {
    const view = await visitView('/account/avatar')

    await view.events.click(view.getByText('Delete'))

    await checkResult(view, { deleted: true, image: '' })
  })

  it('can upload image from camera', async () => {
    const view = await visitView('/account/avatar')

    const file = new File([], 'test.jpg', { type: 'image/jpeg' })

    await view.events.upload(view.getByTestId('fileCameraInput'), file)

    await checkResult(view, { deleted: false, image: 'cropped image url' })
  })

  it('can upload image from gallery', async () => {
    const view = await visitView('/account/avatar')

    const file = new File([], 'test.jpg', { type: 'image/jpeg' })

    await view.events.upload(view.getByTestId('fileGalleryInput'), file)

    await checkResult(view, { deleted: false, image: 'cropped image url' })
  })

  it('even after deleting it has an image', async () => {
    const view = await visitView('/account/avatar')

    const file = new File([], 'test.jpg', { type: 'image/jpeg' })

    await view.events.click(view.getByText('Delete'))
    await view.events.upload(view.getByTestId('fileGalleryInput'), file)

    await checkResult(view, { deleted: false, image: 'cropped image url' })
  })

  it('after selecting image i can delete my avatar', async () => {
    const view = await visitView('/account/avatar')

    const file = new File([], 'test.jpg', { type: 'image/jpeg' })

    await view.events.upload(view.getByTestId('fileGalleryInput'), file)
    await view.events.click(view.getByText('Delete'))

    await checkResult(view, { deleted: true, image: '' })
  })
})
