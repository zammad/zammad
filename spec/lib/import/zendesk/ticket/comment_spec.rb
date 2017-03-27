require 'rails_helper'

RSpec.describe Import::Zendesk::Ticket::Comment do

  context 'email' do

    it 'creates' do

      comment = double(
        id:        1337,
        author_id: 42,
        public:    true,
        html_body: '<div>Hello World!</div>',
        via:       double(
          channel: 'email',
          source:  double(
            from: double(address: 'from@sender.tld'),
            to:   double(address: 'to@receiver.tld')
          ),
        ),
        attachments: []
      )

      local_ticket = double(id: 31_337)

      local_user_id = 99

      create_structure = {
        from:          comment.via.source.from.address,
        to:            comment.via.source.to.address,
        ticket_id:     local_ticket.id,
        body:          comment.html_body,
        content_type:  'text/html',
        internal:      !comment.public,
        message_id:    comment.id,
        updated_by_id: local_user_id,
        created_by_id: local_user_id,
        sender_id:     23,
        type_id:       1,
      }

      expect(Import::Zendesk::UserFactory).to receive(:local_id).with( comment.author_id ).and_return(local_user_id)
      expect(Import::Zendesk::Ticket::Comment::Sender).to receive(:local_id).with(local_user_id).and_return(create_structure[:sender_id])

      expect(::Ticket::Article).to receive(:find_by).with(message_id: comment.id)

      expect(::Ticket::Article).to receive(:create).with(create_structure)

      described_class.new(comment, local_ticket, nil)
    end

    it 'updates' do

      comment = double(
        id:        1337,
        author_id: 42,
        public:    true,
        html_body: '<div>Hello World!</div>',
        via:       double(
          channel: 'email',
          source:  double(
            from: double(address: 'from@sender.tld'),
            to:   double(address: 'to@receiver.tld')
          ),
        ),
        attachments: []
      )

      local_ticket = double(id: 31_337)

      local_user_id = 99

      update_structure = {
        from:          comment.via.source.from.address,
        to:            comment.via.source.to.address,
        ticket_id:     local_ticket.id,
        body:          comment.html_body,
        content_type:  'text/html',
        internal:      !comment.public,
        message_id:    comment.id,
        updated_by_id: local_user_id,
        created_by_id: local_user_id,
        sender_id:     23,
        type_id:       1,
      }

      expect(Import::Zendesk::UserFactory).to receive(:local_id).with( comment.author_id ).and_return(local_user_id)
      expect(Import::Zendesk::Ticket::Comment::Sender).to receive(:local_id).with(local_user_id).and_return(update_structure[:sender_id])

      local_article = double()
      expect(local_article).to receive(:update_attributes).with(update_structure)

      expect(::Ticket::Article).to receive(:find_by).with(message_id: comment.id).and_return(local_article)

      described_class.new(comment, local_ticket, nil)
    end
  end

  context 'facebook' do

    context 'post' do

      it 'creates' do

        comment = double(
          id:        1337,
          author_id: 42,
          public:    true,
          html_body: '<div>Hello World!</div>',
          via:       double(
            channel: 'facebook',
            source:  double(
              from: double(facebook_id: 3_129_033),
              to:   double(facebook_id: 1_230_920),
              rel:  'post',
            ),
          ),
          attachments: []
        )

        local_ticket = double(id: 31_337)

        local_user_id = 99

        create_structure = {
          from:          comment.via.source.from.facebook_id,
          to:            comment.via.source.to.facebook_id,
          ticket_id:     local_ticket.id,
          body:          comment.html_body,
          content_type:  'text/html',
          internal:      !comment.public,
          message_id:    comment.id,
          updated_by_id: local_user_id,
          created_by_id: local_user_id,
          sender_id:     23,
          type_id:       8,
        }

        expect(Import::Zendesk::UserFactory).to receive(:local_id).with( comment.author_id ).and_return(local_user_id)
        expect(Import::Zendesk::Ticket::Comment::Sender).to receive(:local_id).with(local_user_id).and_return(create_structure[:sender_id])

        expect(::Ticket::Article).to receive(:find_by).with(message_id: comment.id)

        expect(::Ticket::Article).to receive(:create).with(create_structure)

        described_class.new(comment, local_ticket, nil)
      end

      it 'updates' do

        comment = double(
          id:        1337,
          author_id: 42,
          public:    true,
          html_body: '<div>Hello World!</div>',
          via:       double(
            channel: 'facebook',
            source:  double(
              from: double(facebook_id: 3_129_033),
              to:   double(facebook_id: 1_230_920),
              rel:  'post',
            ),
          ),
          attachments: []
        )

        local_ticket = double(id: 31_337)

        local_user_id = 99

        update_structure = {
          from:          comment.via.source.from.facebook_id,
          to:            comment.via.source.to.facebook_id,
          ticket_id:     local_ticket.id,
          body:          comment.html_body,
          content_type:  'text/html',
          internal:      !comment.public,
          message_id:    comment.id,
          updated_by_id: local_user_id,
          created_by_id: local_user_id,
          sender_id:     23,
          type_id:       8,
        }

        expect(Import::Zendesk::UserFactory).to receive(:local_id).with( comment.author_id ).and_return(local_user_id)
        expect(Import::Zendesk::Ticket::Comment::Sender).to receive(:local_id).with(local_user_id).and_return(update_structure[:sender_id])

        local_article = double()
        expect(local_article).to receive(:update_attributes).with(update_structure)

        expect(::Ticket::Article).to receive(:find_by).with(message_id: comment.id).and_return(local_article)

        described_class.new(comment, local_ticket, nil)
      end
    end

    context 'comment' do

      it 'creates' do

        comment = double(
          id:        1337,
          author_id: 42,
          public:    true,
          html_body: '<div>Hello World!</div>',
          via:       double(
            channel: 'facebook',
            source:  double(
              from: double(facebook_id: 3_129_033),
              to:   double(facebook_id: 1_230_920),
              rel:  'comment',
            ),
          ),
          attachments: []
        )

        local_ticket = double(id: 31_337)

        local_user_id = 99

        create_structure = {
          from:          comment.via.source.from.facebook_id,
          to:            comment.via.source.to.facebook_id,
          ticket_id:     local_ticket.id,
          body:          comment.html_body,
          content_type:  'text/html',
          internal:      !comment.public,
          message_id:    comment.id,
          updated_by_id: local_user_id,
          created_by_id: local_user_id,
          sender_id:     23,
          type_id:       9,
        }

        expect(Import::Zendesk::UserFactory).to receive(:local_id).with( comment.author_id ).and_return(local_user_id)
        expect(Import::Zendesk::Ticket::Comment::Sender).to receive(:local_id).with(local_user_id).and_return(create_structure[:sender_id])

        expect(::Ticket::Article).to receive(:find_by).with(message_id: comment.id)

        expect(::Ticket::Article).to receive(:create).with(create_structure)

        described_class.new(comment, local_ticket, nil)
      end

      it 'updates' do

        comment = double(
          id:        1337,
          author_id: 42,
          public:    true,
          html_body: '<div>Hello World!</div>',
          via:       double(
            channel: 'facebook',
            source:  double(
              from: double(facebook_id: 3_129_033),
              to:   double(facebook_id: 1_230_920),
              rel:  'comment',
            ),
          ),
          attachments: []
        )

        local_ticket = double(id: 31_337)

        local_user_id = 99

        update_structure = {
          from:          comment.via.source.from.facebook_id,
          to:            comment.via.source.to.facebook_id,
          ticket_id:     local_ticket.id,
          body:          comment.html_body,
          content_type:  'text/html',
          internal:      !comment.public,
          message_id:    comment.id,
          updated_by_id: local_user_id,
          created_by_id: local_user_id,
          sender_id:     23,
          type_id:       9,
        }

        expect(Import::Zendesk::UserFactory).to receive(:local_id).with( comment.author_id ).and_return(local_user_id)
        expect(Import::Zendesk::Ticket::Comment::Sender).to receive(:local_id).with(local_user_id).and_return(update_structure[:sender_id])

        local_article = double()
        expect(local_article).to receive(:update_attributes).with(update_structure)

        expect(::Ticket::Article).to receive(:find_by).with(message_id: comment.id).and_return(local_article)

        described_class.new(comment, local_ticket, nil)
      end
    end
  end

  context 'twitter' do

    context 'mention' do

      it 'creates' do

        comment = double(
          id:        1337,
          author_id: 42,
          public:    true,
          html_body: '<div>Hello World!</div>',
          via:       double(
            channel: 'twitter',
            source:  double(
              rel:  'mention',
            ),
          ),
          attachments: []
        )

        local_ticket = double(id: 31_337)

        local_user_id = 99

        create_structure = {
          ticket_id:     local_ticket.id,
          body:          comment.html_body,
          content_type:  'text/html',
          internal:      !comment.public,
          message_id:    comment.id,
          updated_by_id: local_user_id,
          created_by_id: local_user_id,
          sender_id:     23,
          type_id:       6,
        }

        expect(Import::Zendesk::UserFactory).to receive(:local_id).with( comment.author_id ).and_return(local_user_id)
        expect(Import::Zendesk::Ticket::Comment::Sender).to receive(:local_id).with(local_user_id).and_return(create_structure[:sender_id])

        expect(::Ticket::Article).to receive(:find_by).with(message_id: comment.id)

        expect(::Ticket::Article).to receive(:create).with(create_structure)

        described_class.new(comment, local_ticket, nil)
      end

      it 'updates' do

        comment = double(
          id:        1337,
          author_id: 42,
          public:    true,
          html_body: '<div>Hello World!</div>',
          via:       double(
            channel: 'twitter',
            source:  double(
              rel:  'mention',
            ),
          ),
          attachments: []
        )

        local_ticket = double(id: 31_337)

        local_user_id = 99

        update_structure = {
          ticket_id:     local_ticket.id,
          body:          comment.html_body,
          content_type:  'text/html',
          internal:      !comment.public,
          message_id:    comment.id,
          updated_by_id: local_user_id,
          created_by_id: local_user_id,
          sender_id:     23,
          type_id:       6,
        }

        expect(Import::Zendesk::UserFactory).to receive(:local_id).with( comment.author_id ).and_return(local_user_id)
        expect(Import::Zendesk::Ticket::Comment::Sender).to receive(:local_id).with(local_user_id).and_return(update_structure[:sender_id])

        local_article = double()
        expect(local_article).to receive(:update_attributes).with(update_structure)

        expect(::Ticket::Article).to receive(:find_by).with(message_id: comment.id).and_return(local_article)

        described_class.new(comment, local_ticket, nil)
      end
    end

    context 'direct_message' do

      it 'creates' do

        comment = double(
          id:        1337,
          author_id: 42,
          public:    true,
          html_body: '<div>Hello World!</div>',
          via:       double(
            channel: 'twitter',
            source:  double(
              rel:  'direct_message',
            ),
          ),
          attachments: []
        )

        local_ticket = double(id: 31_337)

        local_user_id = 99

        create_structure = {
          ticket_id:     local_ticket.id,
          body:          comment.html_body,
          content_type:  'text/html',
          internal:      !comment.public,
          message_id:    comment.id,
          updated_by_id: local_user_id,
          created_by_id: local_user_id,
          sender_id:     23,
          type_id:       7,
        }

        expect(Import::Zendesk::UserFactory).to receive(:local_id).with( comment.author_id ).and_return(local_user_id)
        expect(Import::Zendesk::Ticket::Comment::Sender).to receive(:local_id).with(local_user_id).and_return(create_structure[:sender_id])

        expect(::Ticket::Article).to receive(:find_by).with(message_id: comment.id)

        expect(::Ticket::Article).to receive(:create).with(create_structure)

        described_class.new(comment, local_ticket, nil)
      end

      it 'updates' do

        comment = double(
          id:        1337,
          author_id: 42,
          public:    true,
          html_body: '<div>Hello World!</div>',
          via:       double(
            channel: 'twitter',
            source:  double(
              rel:  'direct_message',
            ),
          ),
          attachments: []
        )

        local_ticket = double(id: 31_337)

        local_user_id = 99

        update_structure = {
          ticket_id:     local_ticket.id,
          body:          comment.html_body,
          content_type:  'text/html',
          internal:      !comment.public,
          message_id:    comment.id,
          updated_by_id: local_user_id,
          created_by_id: local_user_id,
          sender_id:     23,
          type_id:       7,
        }

        expect(Import::Zendesk::UserFactory).to receive(:local_id).with( comment.author_id ).and_return(local_user_id)
        expect(Import::Zendesk::Ticket::Comment::Sender).to receive(:local_id).with(local_user_id).and_return(update_structure[:sender_id])

        local_article = double()
        expect(local_article).to receive(:update_attributes).with(update_structure)

        expect(::Ticket::Article).to receive(:find_by).with(message_id: comment.id).and_return(local_article)

        described_class.new(comment, local_ticket, nil)
      end
    end
  end

  context 'web' do

    it 'creates' do

      comment = double(
        id:        1337,
        author_id: 42,
        public:    true,
        html_body: '<div>Hello World!</div>',
        via:       double(
          channel: 'web',
        ),
        attachments: []
      )

      local_ticket = double(id: 31_337)

      local_user_id = 99

      create_structure = {
        ticket_id:     local_ticket.id,
        body:          comment.html_body,
        content_type:  'text/html',
        internal:      !comment.public,
        message_id:    comment.id,
        updated_by_id: local_user_id,
        created_by_id: local_user_id,
        sender_id:     23,
        type_id:       11,
      }

      expect(Import::Zendesk::UserFactory).to receive(:local_id).with( comment.author_id ).and_return(local_user_id)
      expect(Import::Zendesk::Ticket::Comment::Sender).to receive(:local_id).with(local_user_id).and_return(create_structure[:sender_id])

      expect(::Ticket::Article).to receive(:find_by).with(message_id: comment.id)

      expect(::Ticket::Article).to receive(:create).with(create_structure)

      described_class.new(comment, local_ticket, nil)
    end

    it 'updates' do

      comment = double(
        id:        1337,
        author_id: 42,
        public:    true,
        html_body: '<div>Hello World!</div>',
        via:       double(
          channel: 'web',
        ),
        attachments: []
      )

      local_ticket = double(id: 31_337)

      local_user_id = 99

      update_structure = {
        ticket_id:     local_ticket.id,
        body:          comment.html_body,
        content_type:  'text/html',
        internal:      !comment.public,
        message_id:    comment.id,
        updated_by_id: local_user_id,
        created_by_id: local_user_id,
        sender_id:     23,
        type_id:       11,
      }

      expect(Import::Zendesk::UserFactory).to receive(:local_id).with( comment.author_id ).and_return(local_user_id)
      expect(Import::Zendesk::Ticket::Comment::Sender).to receive(:local_id).with(local_user_id).and_return(update_structure[:sender_id])

      local_article = double()
      expect(local_article).to receive(:update_attributes).with(update_structure)

      expect(::Ticket::Article).to receive(:find_by).with(message_id: comment.id).and_return(local_article)

      described_class.new(comment, local_ticket, nil)
    end
  end

  context 'sample_ticket' do

    it 'creates' do

      comment = double(
        id:        1337,
        author_id: 42,
        public:    true,
        html_body: '<div>Hello World!</div>',
        via:       double(
          channel: 'sample_ticket',
        ),
        attachments: []
      )

      local_ticket = double(id: 31_337)

      local_user_id = 99

      create_structure = {
        ticket_id:     local_ticket.id,
        body:          comment.html_body,
        content_type:  'text/html',
        internal:      !comment.public,
        message_id:    comment.id,
        updated_by_id: local_user_id,
        created_by_id: local_user_id,
        sender_id:     23,
        type_id:       10,
      }

      expect(Import::Zendesk::UserFactory).to receive(:local_id).with( comment.author_id ).and_return(local_user_id)
      expect(Import::Zendesk::Ticket::Comment::Sender).to receive(:local_id).with(local_user_id).and_return(create_structure[:sender_id])

      expect(::Ticket::Article).to receive(:find_by).with(message_id: comment.id)

      expect(::Ticket::Article).to receive(:create).with(create_structure)

      described_class.new(comment, local_ticket, nil)
    end

    it 'updates' do

      comment = double(
        id:        1337,
        author_id: 42,
        public:    true,
        html_body: '<div>Hello World!</div>',
        via:       double(
          channel: 'sample_ticket',
        ),
        attachments: []
      )

      local_ticket = double(id: 31_337)

      local_user_id = 99

      update_structure = {
        ticket_id:     local_ticket.id,
        body:          comment.html_body,
        content_type:  'text/html',
        internal:      !comment.public,
        message_id:    comment.id,
        updated_by_id: local_user_id,
        created_by_id: local_user_id,
        sender_id:     23,
        type_id:       10,
      }

      expect(Import::Zendesk::UserFactory).to receive(:local_id).with( comment.author_id ).and_return(local_user_id)
      expect(Import::Zendesk::Ticket::Comment::Sender).to receive(:local_id).with(local_user_id).and_return(update_structure[:sender_id])

      local_article = double()
      expect(local_article).to receive(:update_attributes).with(update_structure)

      expect(::Ticket::Article).to receive(:find_by).with(message_id: comment.id).and_return(local_article)

      described_class.new(comment, local_ticket, nil)
    end
  end

end
