require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/can_be_imported_examples'
require 'models/concerns/has_object_manager_attributes_validation_examples'

RSpec.describe Ticket::Article, type: :model do
  it_behaves_like 'ApplicationModel'
  it_behaves_like 'CanBeImported'
  it_behaves_like 'HasObjectManagerAttributesValidation'

  describe 'Callbacks, Observers, & Async Transactions' do
    describe 'NULL byte handling (via ChecksAttributeValuesAndLength concern):' do
      it 'removes them from #subject on creation, if necessary (postgres doesn’t like them)' do
        expect(create(:ticket_article, subject: "com test 1\u0000"))
          .to be_persisted
      end

      it 'removes them from #body on creation, if necessary (postgres doesn’t like them)' do
        expect(create(:ticket_article, body: "some\u0000message 123"))
          .to be_persisted
      end
    end

    describe 'Cti::Log syncing:' do
      context 'with existing Log records' do
        context 'for an incoming call from an unknown number' do
          let!(:log) { create(:'cti/log', :with_preferences, from: '491111222222', direction: 'in') }

          context 'with that number in #body' do
            subject(:article) { build(:ticket_article, body: <<~BODY) }
              some message
              +49 1111 222222
            BODY

            it 'does not modify any Log records (because CallerIds from article bodies have #level "maybe")' do
              expect do
                article.save
                Observer::Transaction.commit
                Scheduler.worker(true)
              end.not_to change { log.reload.attributes }
            end
          end
        end
      end
    end

    describe 'Auto-setting of outgoing Twitter article attributes (via bj jobs):' do
      subject!(:twitter_article) { create(:twitter_article, sender_name: 'Agent') }
      let(:channel) { Channel.find(twitter_article.ticket.preferences[:channel_id]) }

      let(:run_bg_jobs) do
        lambda do
          VCR.use_cassette(cassette, match_requests_on: %i[method uri oauth_headers]) do
            Scheduler.worker(true)
          end
        end
      end

      let(:cassette) { 'models/channel/driver/twitter/article_to_tweet' }

      it 'sets #from to sender’s Twitter handle' do
        expect(&run_bg_jobs)
          .to change { twitter_article.reload.from }
          .to('@example')
      end

      it 'sets #to to recipient’s Twitter handle' do
        expect(&run_bg_jobs)
          .to change { twitter_article.reload.to }
          .to('') # Tweet in VCR cassette is addressed to no one
      end

      it 'sets #message_id to tweet ID (https://twitter.com/statuses/<id>)' do
        expect(&run_bg_jobs)
          .to change { twitter_article.reload.message_id }
          .to('1069382411899817990')
      end

      it 'sets #preferences with tweet metadata' do
        expect(&run_bg_jobs)
          .to change { twitter_article.reload.preferences }
          .to(hash_including('twitter', 'links'))

        expect(twitter_article.preferences[:links].first)
          .to include(
            'name'   => 'on Twitter',
            'target' => '_blank',
            'url'    => "https://twitter.com/statuses/#{twitter_article.message_id}"
          )
      end

      it 'does not change #cc' do
        expect(&run_bg_jobs).not_to change { twitter_article.reload.cc }
      end

      it 'does not change #subject' do
        expect(&run_bg_jobs).not_to change { twitter_article.reload.subject }
      end

      it 'does not change #content_type' do
        expect(&run_bg_jobs).not_to change { twitter_article.reload.content_type }
      end

      it 'does not change #body' do
        expect(&run_bg_jobs).not_to change { twitter_article.reload.body }
      end

      it 'does not change #sender' do
        expect(&run_bg_jobs).not_to change { twitter_article.reload.sender }
      end

      it 'does not change #type' do
        expect(&run_bg_jobs).not_to change { twitter_article.reload.type }
      end

      it 'sets appropriate status attributes on the ticket’s channel' do
        expect(&run_bg_jobs)
          .to change { channel.reload.attributes }
          .to hash_including(
            'status_in'    => nil,
            'last_log_in'  => nil,
            'status_out'   => 'ok',
            'last_log_out' => ''
          )
      end

      context 'when the original channel (specified in ticket.preferences) was deleted' do
        context 'but a new one with the same screen_name exists' do
          let(:cassette)    { 'models/channel/driver/twitter/article_to_tweet_channel_replace' }
          let(:new_channel) { create(:twitter_channel) }

          before do
            channel.destroy

            expect(new_channel.options[:user][:screen_name])
              .to eq(channel.options[:user][:screen_name])
          end

          it 'sets appropriate status attributes on the new channel' do
            expect(&run_bg_jobs)
              .to change { new_channel.reload.attributes }
              .to hash_including(
                'status_in'    => nil,
                'last_log_in'  => nil,
                'status_out'   => 'ok',
                'last_log_out' => ''
              )
          end
        end
      end
    end
  end

  describe 'clone attachments' do
    context 'of forwarded article' do
      context 'via email' do

        it 'only need to clone attached attachments' do
          article_parent = create(:ticket_article,
                                  type:         Ticket::Article::Type.find_by(name: 'email'),
                                  content_type: 'text/html',
                                  body:         '<img src="cid:15.274327094.140938@zammad.example.com"> some text',)
          Store.add(
            object:        'Ticket::Article',
            o_id:          article_parent.id,
            data:          'content_file1_normally_should_be_an_image',
            filename:      'some_file1.jpg',
            preferences:   {
              'Content-Type'        => 'image/jpeg',
              'Mime-Type'           => 'image/jpeg',
              'Content-ID'          => '15.274327094.140938@zammad.example.com',
              'Content-Disposition' => 'inline',
            },
            created_by_id: 1,
          )
          Store.add(
            object:        'Ticket::Article',
            o_id:          article_parent.id,
            data:          'content_file2_normally_should_be_an_image',
            filename:      'some_file2.jpg',
            preferences:   {
              'Content-Type'        => 'image/jpeg',
              'Mime-Type'           => 'image/jpeg',
              'Content-ID'          => '15.274327094.140938_not_reffered@zammad.example.com',
              'Content-Disposition' => 'inline',
            },
            created_by_id: 1,
          )
          Store.add(
            object:        'Ticket::Article',
            o_id:          article_parent.id,
            data:          'content_file3_normally_should_be_an_image',
            filename:      'some_file3.jpg',
            preferences:   {
              'Content-Type'        => 'image/jpeg',
              'Mime-Type'           => 'image/jpeg',
              'Content-Disposition' => 'attached',
            },
            created_by_id: 1,
          )
          article_new = create(:ticket_article)
          UserInfo.current_user_id = 1

          attachments = article_parent.clone_attachments(article_new.class.name, article_new.id, only_attached_attachments: true)

          expect(attachments.count).to eq(2)
          expect(attachments[0].filename).to eq('some_file2.jpg')
          expect(attachments[1].filename).to eq('some_file3.jpg')
        end
      end
    end

    context 'of trigger' do
      context 'via email notifications' do
        it 'only need to clone inline attachments used in body' do
          article_parent = create(:ticket_article,
                                  type:         Ticket::Article::Type.find_by(name: 'email'),
                                  content_type: 'text/html',
                                  body:         '<img src="cid:15.274327094.140938@zammad.example.com"> some text',)
          Store.add(
            object:        'Ticket::Article',
            o_id:          article_parent.id,
            data:          'content_file1_normally_should_be_an_image',
            filename:      'some_file1.jpg',
            preferences:   {
              'Content-Type'        => 'image/jpeg',
              'Mime-Type'           => 'image/jpeg',
              'Content-ID'          => '15.274327094.140938@zammad.example.com',
              'Content-Disposition' => 'inline',
            },
            created_by_id: 1,
          )
          Store.add(
            object:        'Ticket::Article',
            o_id:          article_parent.id,
            data:          'content_file2_normally_should_be_an_image',
            filename:      'some_file2.jpg',
            preferences:   {
              'Content-Type'        => 'image/jpeg',
              'Mime-Type'           => 'image/jpeg',
              'Content-ID'          => '15.274327094.140938_not_reffered@zammad.example.com',
              'Content-Disposition' => 'inline',
            },
            created_by_id: 1,
          )

          # #2483 - #{article.body_as_html} now includes attachments (e.g. PDFs)
          # Regular attachments do not get assigned a Content-ID, and should not be copied in this use case
          Store.add(
            object:        'Ticket::Article',
            o_id:          article_parent.id,
            data:          'content_file3_with_no_content_id',
            filename:      'some_file3.jpg',
            preferences:   {
              'Content-Type' => 'image/jpeg',
              'Mime-Type'    => 'image/jpeg',
            },
            created_by_id: 1,
          )

          article_new = create(:ticket_article)
          UserInfo.current_user_id = 1

          attachments = article_parent.clone_attachments(article_new.class.name, article_new.id, only_inline_attachments: true )

          expect(attachments.count).to eq(1)
          expect(attachments[0].filename).to eq('some_file1.jpg')
        end
      end
    end
  end
end
