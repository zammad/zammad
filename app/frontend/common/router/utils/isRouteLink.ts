// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { Link } from '@common/types/router'
import { useRouter } from 'vue-router'

export default function isRouteLink(link: Link): boolean {
  if (typeof link === 'object') return true

  const router = useRouter()
  const resolved = router.resolve(link)

  return (
    resolved !== null &&
    resolved.matched.length > 0 &&
    resolved.name !== 'Error'
  )
}
