import { createApp } from 'vue'
import App from '@mobile/App.vue'

export default function mountApp(): void {
  createApp(App).mount('#app')
}
