require 'rails_helper'

RSpec.describe Channel::EmailParser, type: :model do
  let(:ticket) { create(:ticket) }
  let(:mail_file) { Rails.root.join('test', 'data', 'mail', 'mail001.box') }
  let(:raw_mail) { File.read(mail_file).sub(/(?<=^Subject: ).*$/, test_string) }
  let(:test_string) do
    Setting.get('ticket_hook') + Setting.get('ticket_hook_divider') + ticket.number
  end

  describe '#process' do
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
end
