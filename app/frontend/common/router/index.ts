import authenticationGuard from '@common/router/guards/authentication'
import { App } from 'vue'
import {
  createRouter,
  createWebHashHistory,
  Router,
  RouteRecordRaw,
} from 'vue-router'

export default function initializeRouter(
  app: App,
  routes: Array<RouteRecordRaw>,
): Router {
  const router: Router = createRouter({
    history: createWebHashHistory(),
    routes,
  })

  router.beforeEach(authenticationGuard)

  app.use(router)

  return router
}
