require 'rails_helper'

RSpec.describe Channel::EmailParser, type: :model do
  let(:subject)   { described_class.new }
  let(:mail_file) { Rails.root.join('test', 'data', 'mail', 'mail001.box') }
  let(:raw_mail)  { File.read(mail_file) }

  describe '#process' do
    let(:raw_mail)    { File.read(mail_file).sub(/(?<=^Subject: ).*$/, test_string) }
    let(:test_string) { Setting.get('ticket_hook') + Setting.get('ticket_hook_divider') + ticket.number }
    let(:ticket)      { create(:ticket) }

    context 'for creating new users' do
      context 'with one unrecognized email address' do
        let(:raw_mail) { <<~RAW }
          From: #{Faker::Internet.unique.email}
          To: #{User.pluck(:email).reject(&:blank?).sample}
          Subject: Foo bar

          Lorem ipsum dolor
        RAW

        it 'creates one new user' do
          expect { Channel::EmailParser.new.process({}, raw_mail) }
            .to change { User.count }.by(1)
        end
      end

      context 'with a large number (42+) of unrecognized email addresses' do
        let(:raw_mail) { <<~RAW }
          From: #{Faker::Internet.unique.email}
          To: #{Array.new(22) { Faker::Internet.unique.email }.join(', ')}
          Cc: #{Array.new(22) { Faker::Internet.unique.email }.join(', ')}
          Subject: test max sender identify

          Some Text
        RAW

        it 'never creates more than 41 users per email' do
          expect { Channel::EmailParser.new.process({}, raw_mail) }
            .to change { User.count }.by(41)
        end
      end
    end

    context 'for associating emails to tickets' do
      context 'when email subject contains ticket reference' do
        it 'adds message to ticket' do
          expect { described_class.new.process({}, raw_mail) }
            .to change { ticket.articles.length }
        end
      end

      context 'when configured to search body' do
        before { Setting.set('postmaster_follow_up_search_in', 'body') }

        context 'when body contains ticket reference' do
          context 'in visible text' do
            let(:raw_mail) { File.read(mail_file).sub(/Hallo =\nMartin,(?=<o:p>)/, test_string) }

            it 'adds message to ticket' do
              expect { described_class.new.process({}, raw_mail) }
                .to change { ticket.articles.length }
            end
          end

          context 'as part of a larger word' do
            let(:raw_mail) { File.read(mail_file).sub(/(?<=Hallo) =\n(?=Martin,<o:p>)/, test_string) }

            it 'creates a separate ticket' do
              expect { described_class.new.process({}, raw_mail) }
                .not_to change { ticket.articles.length }
            end
          end

          context 'in html attributes' do
            let(:raw_mail) { File.read(mail_file).sub(%r{<a href.*?/a>}m, %(<table bgcolor="#{test_string}"> </table>)) }

            it 'creates a separate ticket' do
              expect { described_class.new.process({}, raw_mail) }
                .not_to change { ticket.articles.length }
            end
          end
        end
      end
    end

    context 'for sender/recipient address formatting' do
      # see https://github.com/zammad/zammad/issues/2198
      context 'when sender address contains spaces (#2198)' do
        let(:mail_file) { Rails.root.join('test', 'data', 'mail', 'mail071.box') }
        let(:sender_email) { 'powerquadrantsystem@example.com' }

        it 'removes them before creating a new user' do
          expect { described_class.new.process({}, raw_mail) }
            .to change { User.where(email: sender_email).count }.to(1)
        end

        it 'marks new user email as invalid' do
          described_class.new.process({}, raw_mail)

          expect(User.find_by(email: sender_email).preferences)
            .to include('mail_delivery_failed' => true)
            .and include('mail_delivery_failed_reason' => 'invalid email')
            .and include('mail_delivery_failed_data' => a_kind_of(ActiveSupport::TimeWithZone))
        end
      end

      # see https://github.com/zammad/zammad/issues/2254
      context 'when sender address contains > (#2254)' do
        let(:mail_file) { Rails.root.join('test', 'data', 'mail', 'mail076.box') }
        let(:sender_email) { 'millionslotteryspaintransfer@example.com' }

        it 'removes them before creating a new user' do
          expect { described_class.new.process({}, raw_mail) }
            .to change { User.where(email: sender_email).count }.to(1)
        end

        it 'marks new user email as invalid' do
          described_class.new.process({}, raw_mail)

          expect(User.find_by(email: sender_email).preferences)
            .to include('mail_delivery_failed' => true)
            .and include('mail_delivery_failed_reason' => 'invalid email')
            .and include('mail_delivery_failed_data' => a_kind_of(ActiveSupport::TimeWithZone))
        end
      end
    end

    context 'for charset handling' do
      # see https://github.com/zammad/zammad/issues/2224
      context 'when header specifies Windows-1258 charset (#2224)' do
        let(:mail_file) { Rails.root.join('test', 'data', 'mail', 'mail072.box') }

        it 'does not raise Encoding::ConverterNotFoundError' do
          expect { described_class.new.process({}, raw_mail) }
            .not_to raise_error
        end
      end
    end
  end
end
