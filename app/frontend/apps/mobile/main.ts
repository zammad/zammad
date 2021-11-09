import { createApp } from 'vue'
import App from '@mobile/App.vue'
import { DefaultApolloClient } from '@vue/apollo-composable'
import apolloClient from '@common/server/apollo/client'
import useSessionIdStore from '@common/stores/session/id'
import '@common/styles/main.css'
import initializeStore from '@common/stores'
import InitializeHandler from '@common/initializer'
import useApplicationConfigStore from '@common//stores/application/config'
import initializeRouter from '@common/router/index'
import routes from '@mobile/router'

export default async function mountApp(): Promise<void> {
  const app = createApp(App)

  app.provide(DefaultApolloClient, apolloClient)

  initializeStore(app)
  initializeRouter(app, routes)

  const initializer = new InitializeHandler(
    app,
    import.meta.globEager('/apps/mobile/initializer/*.ts'),
  )

  initializer.initialize()

  const sessionId = useSessionIdStore()
  await sessionId.checkSession()

  const applicationConfig = useApplicationConfigStore()
  await applicationConfig.getConfig()

  app.mount('#app')
}
