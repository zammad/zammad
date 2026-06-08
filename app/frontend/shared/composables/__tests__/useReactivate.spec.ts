// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// import { useReactivate } from '#desktop/composables/useReactivate.ts'

import { onMounted, ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { useReactivate } from '#shared/composables/useReactivate.ts'

describe('useReactivate', () => {
  it('should call callbacks appropriate', () => {
    renderComponent({
      template: `
    <KeepAlive>
       <div v-if="show"/>
    </KeepAlive>`,
      setup() {
        const onActivatedCallback = vi.fn()
        const onDeactivatedCallback = vi.fn()

        const show = ref(true)

        useReactivate(onActivatedCallback, onDeactivatedCallback)

        onMounted(() => {
          // Initial mounting component should not call the callback
          expect(onActivatedCallback).not.toHaveBeenCalled()

          setTimeout(async () => {
            show.value = false
            await waitForNextTick()
            expect(onDeactivatedCallback).toHaveBeenCalled()
            show.value = true
            await waitForNextTick()
            expect(onActivatedCallback).toHaveBeenCalled()
          }, 50)
        })

        return { show }
      },
    })
  })
})
