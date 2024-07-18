<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, provide } from 'vue'

import { useTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.api.ts'
import { useErrorHandler } from '#shared/errors/useErrorHandler.ts'
import { EnumTaskbarEntity } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useTaskbarTab } from '#desktop/entities/user/current/composables/useTaskbarTab.ts'
import TicketDetailTopBar from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TicketDetailTopBar.vue'
import { TICKET_INFORMATION_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

interface Props {
  internalId: string
}

const props = defineProps<Props>()

useTaskbarTab(EnumTaskbarEntity.TicketZoom)

// TODO: create a useTicketInformation-Data composable which provides/inject support
// This could handle then the different data what is needed (e.g. ticket, articles, customer, ...)

const ticketId = computed(() => convertToGraphQLId('Ticket', props.internalId))

const { createQueryErrorHandler } = useErrorHandler()

const ticketQuery = new QueryHandler(
  useTicketQuery(
    () => ({
      ticketId: ticketId.value,
    }),
    {
      fetchPolicy: 'cache-first',
    },
  ),
  {
    errorCallback: createQueryErrorHandler({
      notFound: __(
        'Ticket with specified ID was not found. Try checking the URL for errors.',
      ),
      forbidden: __('You have insufficient rights to view this ticket.'),
    }),
  },
)

const ticketResult = ticketQuery.result()

const ticket = computed(() => ticketResult.value?.ticket)

const isLoadingTicket = computed(() => {
  return ticketQuery.loading().value && !ticket.value
})

provide(TICKET_INFORMATION_KEY, ticket)
</script>

<template>
  <LayoutContent
    name="ticket-create"
    no-padding
    background-variant="primary"
    content-alignment="center"
  >
    <CommonLoader class="mt-8" :loading="isLoadingTicket">
      <div class="relative flex w-full flex-col">
        <TicketDetailTopBar />

        <!--    :TODO Build the real shell -->
        <CommonLink class="mx-auto max-w-xl" link="/tickets/1"
          >Testing Ticket-Link</CommonLink
        >
        <CommonLabel tag="p" class="mx-auto max-w-xl">
          Lorem ipsum dolor sit amet, consectetur adipisicing elit. Adipisci aut
          cumque deleniti deserunt earum eligendi error, facere fugiat hic iure
          libero molestias neque non officiis optio perspiciatis praesentium
          quos reprehenderit sequi ut vero vitae voluptas. Ad adipisci, aliquid
          deserunt dolor doloremque, dolorum est harum impedit natus odio
          pariatur praesentium reprehenderit rerum similique ullam vero
          voluptate. Ab accusamus aliquid architecto, doloremque eveniet ex
          facere facilis fugit iste itaque non odit omnis pariatur praesentium,
          quam quasi quibusdam reiciendis rem tempora unde velit vero,
          voluptates. Autem culpa ex ipsum iste nostrum possimus quam quo rem.
          Aperiam, architecto assumenda delectus distinctio earum eum fuga
          itaque modi nam, necessitatibus nemo nisi, perferendis placeat
          possimus quae quam quos ratione rerum sequi sunt unde velit voluptas
          voluptate. Aspernatur dolorem doloribus, exercitationem ipsa magni
          reiciendis veniam! Ab nemo officiis pariatur totam! Alias amet
          assumenda blanditiis, consequuntur cumque delectus deserunt distinctio
          doloremque doloribus eaque esse et facilis illum ipsa itaque iure
          laboriosam magni maiores modi molestiae mollitia necessitatibus nobis
          omnis possimus provident quam qui quis quisquam quo quos rerum saepe
          sint suscipit tempore ullam veniam veritatis. Ad autem beatae
          exercitationem facere harum ipsam necessitatibus nulla, officia optio
          quo quos ratione suscipit veritatis. Aliquam animi dolorem fugiat rem
          voluptates? Asperiores beatae dicta nesciunt perferendis quidem
          repellendus reprehenderit similique vero. Eum id incidunt magni! Fuga
          fugit quis repudiandae saepe? Accusantium architecto nesciunt
          reprehenderit tempora. Amet deserunt magnam minus nihil, recusandae
          unde. Consequatur nobis quae quos saepe sed totam ullam! At beatae
          incidunt minus perspiciatis! Asperiores dignissimos doloremque minus
          placeat porro? Aliquam animi aspernatur deserunt dolorem doloribus
          eaque earum, esse fuga iste, nulla obcaecati optio placeat possimus
          quam quisquam quo quod repellendus similique, sint sit temporibus
          velit voluptatum. Dicta ipsa magnam nam nisi quam soluta voluptatem,
          voluptatibus. Atque culpa doloremque eligendi fuga fugiat id itaque
          placeat quod similique veritatis. Accusamus ad amet aperiam
          consequuntur deserunt dolore ducimus ea eaque eius eligendi enim est
          ex facere facilis iusto libero magni molestiae, mollitia natus
          possimus quae quia recusandae sed sint soluta totam vel voluptatum.
          Aliquam animi aspernatur at cumque cupiditate, debitis distinctio,
          dolor dolorem doloremque eius eligendi enim error et eum eveniet
          explicabo illum impedit iste, mollitia perferendis praesentium quam
          quasi quia quibusdam ratione recusandae rem repellat tenetur veniam
          vero. At aut deleniti dolorum eius enim facilis ipsam libero minus
          nobis officiis porro quidem quis quo rem, repellat sunt suscipit
          tenetur velit! Asperiores assumenda debitis exercitationem hic, iste
          magnam numquam omnis quaerat quidem quo sequi temporibus ullam?
          Blanditiis eligendi modi molestias optio, rem sapiente sunt. Aperiam
          architecto corporis deserunt earum, eum incidunt magnam officia quod
          suscipit voluptates! Ab animi architecto autem commodi consequatur
          consequuntur cumque debitis, delectus dolor dolore dolorum eos, harum
          illo impedit laudantium molestiae necessitatibus perferendis quod rem
          reprehenderit repudiandae sed tempora veniam, vero vitae. Ab assumenda
          aut corporis culpa, eos error explicabo ipsam ipsum laborum nisi
          perferendis quaerat quas qui quibusdam ratione repudiandae sed,
          veniam? Ad atque consequatur debitis distinctio ea eaque enim
          explicabo fuga libero molestias, omnis quaerat quo reprehenderit sit
          vel! Adipisci at dolorum facere fuga harum hic illo mollitia nemo
          neque nisi nobis odio quaerat, quidem quos recusandae sapiente
          temporibus ullam voluptates. Autem dignissimos minima placeat porro
          soluta? Aspernatur aut debitis dolores, error, maxime modi nobis nulla
          officia porro possimus quo sequi sint! Adipisci aperiam architecto
          aspernatur assumenda consectetur consequuntur dolore dolorum error ex
          facere in, incidunt magnam magni nam necessitatibus optio
          perspiciatis, quae rerum, soluta unde? Aperiam commodi consectetur
          delectus dolorem doloremque eligendi est facere ipsam itaque laborum
          libero magnam numquam odio, pariatur perspiciatis quae quibusdam
          similique sint vero voluptatem? Adipisci aut corporis distinctio, eum
          exercitationem iure nisi nulla optio perferendis provident quia
          similique tempora temporibus. A ab ad aliquam corporis dolore dolorum
          explicabo mollitia, quae quas, quasi saepe tenetur veniam, voluptas.
          Commodi eligendi ipsa molestias praesentium voluptas? Alias atque
          consectetur delectus deleniti dignissimos eos est illum labore maiores
          nam nemo nesciunt pariatur, qui quidem reiciendis? Accusamus
          asperiores quisquam rem? Aliquid deserunt est incidunt ipsa, magni
          perspiciatis unde! Ab distinctio dolor, dolore fugit harum iste,
          laborum non quaerat quis, similique tempore totam. Accusamus aliquid
          amet architecto aspernatur assumenda aut blanditiis consectetur
          consequatur corporis deleniti distinctio eligendi esse ex expedita
          facilis hic impedit iusto laudantium magni maiores minus modi
          molestias, natus nesciunt numquam obcaecati odit omnis possimus, quos
          recusandae repellendus tempore ut velit veritatis vitae voluptate
          voluptates. Aliquid aut beatae corporis culpa debitis dicta est fuga
          fugit iure laborum laudantium magnam, maiores molestias mollitia nemo
          numquam officiis placeat provident ullam unde veniam, voluptas
          voluptatem voluptates. Est nam quia suscipit? Dicta et hic minima
          veniam? Molestias quibusdam reprehenderit vitae! Alias amet animi
          aperiam at atque beatae commodi consectetur cumque debitis deserunt
          doloremque doloribus ducimus esse exercitationem fuga impedit iure
          laborum laudantium neque nobis, officia perspiciatis quibusdam, quis
          ratione recusandae repellat repellendus suscipit, tempora tempore
          totam ullam velit voluptate voluptatibus? Alias aperiam cupiditate
          dolorem excepturi expedita magni mollitia nisi obcaecati quo, ratione
          repellat sequi vel veniam! Amet cum earum omnis perspiciatis unde?
          Accusamus assumenda delectus esse exercitationem expedita fugit ipsa
          libero magni, nesciunt reiciendis suscipit, tenetur vel voluptas
          voluptates voluptatum. A cum ex facilis illum molestiae, natus neque
          nobis numquam perspiciatis quia repellendus reprehenderit sapiente
          sit? Aliquam consequatur dolor dolore doloremque doloribus error et
          fugiat, laborum magni, non officiis perspiciatis provident quas qui
          sit, ut veniam! Ab aliquam animi aut consequuntur dolore dolores
          doloribus dolorum ea, earum excepturi fuga ipsam laborum laudantium
          maiores minus nam natus necessitatibus, non nulla officia perspiciatis
          porro quo quos repellat reprehenderit sapiente sed temporibus ullam
          vitae voluptate. Architecto, atque consequuntur cupiditate iste
          officia quam similique vel. Consectetur esse illum iste nostrum
          numquam officiis omnis porro, quidem! Ab adipisci dolores enim eum
          excepturi facere illum obcaecati sed similique voluptatum? Accusamus
          corporis cum debitis ex illo impedit nesciunt nostrum perspiciatis
          reprehenderit temporibus? Aperiam corporis dicta dignissimos eaque
          impedit iste laborum, magnam maiores molestias obcaecati odio pariatur
          repellendus sed soluta, voluptatum? Accusamus alias amet architecto
          commodi culpa, doloribus eum facere facilis ipsum magnam modi officia
          pariatur provident quam quis ratione voluptatum. Commodi dolor
          doloribus ducimus facere fuga, illo labore maxime nisi nostrum officia
          perspiciatis quaerat, quia sapiente suscipit. Accusamus assumenda
          delectus esse exercitationem expedita fugit ipsa libero magni,
          nesciunt reiciendis suscipit, tenetur vel voluptas voluptates
          voluptatum. A cum ex facilis illum molestiae, natus neque nobis
          numquam perspiciatis quia repellendus reprehenderit sapiente sit?
          Aliquam consequatur dolor dolore doloremque doloribus error et fugiat,
          laborum magni, non officiis perspiciatis provident quas qui sit, ut
          veniam! Ab aliquam animi aut consequuntur dolore dolores doloribus
          dolorum ea, earum excepturi fuga ipsam laborum laudantium maiores
          minus nam natus necessitatibus, non nulla officia perspiciatis porro
          quo quos repellat reprehenderit sapiente sed temporibus ullam vitae
          voluptate. Architecto, atque consequuntur cupiditate iste officia quam
          similique vel. Consectetur esse illum iste nostrum numquam officiis
          omnis porro, quidem! Ab adipisci dolores enim eum excepturi facere
          illum obcaecati sed similique voluptatum? Accusamus corporis cum
          debitis ex illo impedit nesciunt nostrum perspiciatis reprehenderit
          temporibus? Aperiam corporis dicta dignissimos eaque impedit iste
          laborum, magnam maiores molestias obcaecati odio pariatur repellendus
          sed soluta, voluptatum? Accusamus alias amet architecto commodi culpa,
          doloribus eum facere facilis ipsum magnam modi officia pariatur
          provident quam quis ratione voluptatum. Commodi dolor doloribus
          ducimus facere fuga, illo labore maxime nisi nostrum officia
          perspiciatis quaerat, quia sapiente suscipit.
        </CommonLabel>
      </div>
    </CommonLoader>
  </LayoutContent>
</template>
