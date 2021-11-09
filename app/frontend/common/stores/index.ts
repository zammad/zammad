import { App } from 'vue'
import { createPinia, Pinia } from 'pinia'

const store: Pinia = createPinia()

export default function initializeStore(app: App) {
  app.use(store)
}

export { store }
