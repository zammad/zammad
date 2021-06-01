# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Cti::CallerId do
  describe '.extract_numbers' do
    context 'for strings containing arbitrary numbers (<6 digits long)' do
      it 'returns an empty array' do
        expect(described_class.extract_numbers(<<~INPUT.chomp)).to be_empty
          some text
          test 123
        INPUT
      end
    end

    context 'for strings containing a phone number with "(0)" after country code' do
      it 'returns the number in an array, without the leading "(0)"' do
        expect(described_class.extract_numbers(<<~INPUT.chomp)).to eq(['4930600000000'])
          Lorem ipsum dolor sit amet, consectetuer +49 (0) 30 60 00 00 00-0
          adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa.
          Cum sociis natoque penatibus et magnis dis parturient montes, nascetur
          ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu,
          pretium quis, sem. Nulla consequat massa quis enim. Donec pede
          justo, fringilla vel.
        INPUT
      end
    end

    context 'for strings containing a phone number with leading 0 (no country code)' do
      it 'returns the number in an array, using default country code (49)' do
        expect(described_class.extract_numbers(<<~INPUT.chomp)).to eq(['4994221000'])
          GS Oberalteich
          Telefon  09422 1000
          E-Mail:
        INPUT
      end
    end

    context 'for strings containing multiple phone numbers' do
      it 'returns all numbers in an array' do
        expect(described_class.extract_numbers(<<~INPUT.chomp)).to eq(%w[41812886393 41763467214])
          Tel +41 81 288 63 93 / +41 76 346 72 14 ...
        INPUT
      end
    end

    context 'for strings containing US-formatted numbers' do
      it 'returns the numbers in an array correctly' do
        expect(described_class.extract_numbers(<<~INPUT.chomp)).to eq(%w[19494310000 19494310001])
          P: +1 (949) 431 0000
          F: +1 (949) 431 0001
          W: http://znuny
        INPUT
      end
    end
  end

  describe '.normalize_number' do
    it 'does not modify digit-only strings (starting with 1-9)' do
      expect(described_class.normalize_number('5754321')).to eq('5754321')
    end

    it 'strips whitespace' do
      expect(described_class.normalize_number('622 32281')).to eq('62232281')
    end

    it 'strips hyphens' do
      expect(described_class.normalize_number('1-888-407-4747')).to eq('18884074747')
    end

    it 'strips leading pluses' do
      expect(described_class.normalize_number('+49 30 53 00 00 000')).to eq('4930530000000')
      expect(described_class.normalize_number('+49 160 0000000')).to eq('491600000000')
    end

    it 'replaces a single leading zero with the default country code (49)' do
      expect(described_class.normalize_number('092213212')).to eq('4992213212')
      expect(described_class.normalize_number('0271233211')).to eq('49271233211')
      expect(described_class.normalize_number('022 1234567')).to eq('49221234567')
      expect(described_class.normalize_number('09 123 32112')).to eq('49912332112')
      expect(described_class.normalize_number('021 2331231')).to eq('49212331231')
      expect(described_class.normalize_number('021 321123123')).to eq('4921321123123')
      expect(described_class.normalize_number('0150 12345678')).to eq('4915012345678')
      expect(described_class.normalize_number('021-233-9123')).to eq('49212339123')
    end

    it 'strips two leading zeroes' do
      expect(described_class.normalize_number('0049 1234 123456789')).to eq('491234123456789')
      expect(described_class.normalize_number('0043 30 60 00 00 00-0')).to eq('4330600000000')
    end

    it 'strips leading zero from "(0x)" at start of number or after country code' do
      expect(described_class.normalize_number('(09)1234321')).to eq('4991234321')
      expect(described_class.normalize_number('+49 (0) 30 60 00 00 00-0')).to eq('4930600000000')
      expect(described_class.normalize_number('0043 (0) 30 60 00 00 00-0')).to eq('4330600000000')
    end
  end

  describe '.lookup' do
    context 'when given an unrecognized number' do
      it 'returns an empty array' do
        expect(described_class.lookup('1')).to eq([])
      end
    end

    context 'when given a recognized number' do
      subject!(:caller_id) { create(:caller_id, caller_id: number) }

      let(:number) { '1234567890' }

      it 'returns an array with the corresponding CallerId' do
        expect(described_class.lookup(number)).to match_array([caller_id])
      end

      context 'shared by multiple CallerIds' do
        context '(for different users)' do
          subject!(:caller_ids) do
            [create(:caller_id, caller_id: number, user: create(:user)),
             create(:caller_id, caller_id: number, user: create(:user))]
          end

          it 'returns all corresponding CallerId records' do
            expect(described_class.lookup(number)).to match_array(caller_ids)
          end
        end

        context '(for the same user)' do
          subject!(:caller_ids) { create_list(:caller_id, 2, caller_id: number) }

          it 'returns one corresponding CallerId record by MAX(id)' do
            expect(described_class.lookup(number)).to match_array(caller_ids.last(1))
          end
        end

        context '(some for the same user, some for another)' do
          subject!(:caller_ids) do
            [*create_list(:caller_id, 2, caller_id: number, user: create(:user)),
             create(:caller_id, caller_id: number, user: create(:user))]
          end

          it 'returns one CallerId record per unique #user_id, by MAX(id)' do
            expect(described_class.lookup(number)).to match_array(caller_ids.last(2))
          end
        end
      end
    end
  end

  describe '.rebuild' do
    context 'when a User record contains a valid phone number' do
      let!(:user) { create(:agent, phone: '+49 123 456') }

      context 'and no corresponding CallerId exists' do
        it 'generates a CallerId record (with #level "known")' do
          described_class.destroy_all # CallerId already generated in User callback

          expect { described_class.rebuild }
            .to change { described_class.exists?(user_id: user.id, caller_id: '49123456', level: 'known') }
            .to(true)
        end
      end

      it 'does not create duplicate CallerId records' do
        expect { described_class.rebuild }.not_to change(described_class, :count)
      end
    end

    context 'when no User exists for a given CallerId record' do
      subject!(:caller_id) { create(:caller_id) }

      it 'deletes the CallerId record' do
        expect { described_class.rebuild }
          .to change { described_class.exists?(caller_id.id) }.to(false)
      end
    end

    context 'when two User records contains the same valid phone number' do
      let!(:users) { create_list(:agent, 2, phone: '+49 123 456') }

      it 'generates two corresponding CallerId records (with #level "known")' do
        described_class.destroy_all # CallerId already generated in User callback

        expect { described_class.rebuild }
          .to change { described_class.exists?(user_id: users.first.id, caller_id: '49123456', level: 'known') }
          .to(true)
          .and change { described_class.exists?(user_id: users.last.id, caller_id: '49123456', level: 'known') }
          .to(true)
      end
    end

    context 'when an Article record contains a valid phone number in its body' do
      let!(:article) { create(:ticket_article, body: <<~BODY, sender_name: sender_name) }
        some message
        Fon (GEL): +49 123-456 Mi-Fr
      BODY

      context 'and comes from a customer' do
        let(:sender_name) { 'Customer' }

        it 'generates a CallerId record (with #level "maybe")' do
          described_class.destroy_all # CallerId already generated in Article observer job

          expect { described_class.rebuild }
            .to change { described_class.exists?(user_id: article.created_by_id, caller_id: '49123456', level: 'maybe') }
            .to(true)
        end
      end

      context 'and comes from an Agent' do
        let(:sender_name) { 'Agent' }

        it 'does not generate a CallerId record' do
          expect { described_class.rebuild }
            .not_to change { described_class.exists?(caller_id: '49123456') }
        end
      end
    end
  end

  describe '.maybe_add' do
    let(:attributes) { attributes_for(:caller_id) }

    it 'wraps .find_or_initialize_by (passing only five defining attributes)' do
      expect(described_class)
        .to receive(:find_or_initialize_by)
        .with(attributes.slice(:caller_id, :level, :object, :o_id, :user_id))
        .and_call_original

      described_class.maybe_add(attributes)
    end

    context 'if no matching record found' do
      it 'adds given #comment attribute' do
        expect { described_class.maybe_add(attributes.merge(comment: 'foo')) }
          .to change(described_class, :count).by(1)

        expect(described_class.last.comment).to eq('foo')
      end
    end

    context 'if matching record found' do
      let(:attributes) { caller_id.attributes.symbolize_keys }
      let(:caller_id) { create(:caller_id) }

      it 'ignores given #comment attribute' do
        expect(described_class.maybe_add(attributes.merge(comment: 'foo')))
          .to eq(caller_id)

        expect(caller_id.comment).to be_blank
      end
    end
  end

  describe '.known_agents_by_number' do
    context 'with known agent caller_id' do
      let!(:agent1) { create(:agent, phone: '0123456') }
      let!(:agent2) { create(:agent, phone: '0123457') }

      it 'gives matching agents' do
        expect(described_class.known_agents_by_number('49123456'))
          .to match_array([agent1])
      end
    end

    context 'with known customer caller_id' do
      let!(:customer1) { create(:customer, phone: '0123456') }

      it 'returns an empty array' do
        expect(described_class.known_agents_by_number('49123456')).to eq([])
      end
    end

    context 'with maybe caller_id' do
      let(:ticket1) do
        create(:ticket_article, created_by_id: customer2.id, body: 'some text 0123457') # create ticket
        TransactionDispatcher.commit
        Scheduler.worker(true)
      end
      let!(:customer2) { create(:customer) }

      it 'returns an empty array' do
        expect(described_class.known_agents_by_number('49123457').count).to eq(0)
      end
    end
  end

  describe 'callbacks' do
    subject!(:caller_id) { build(:cti_caller_id, caller_id: phone) }

    let(:phone) { '1234567890' }

    describe 'on creation' do
      it 'adopts CTI Logs from same number (via UpdateCtiLogsByCallerJob)' do
        expect(UpdateCtiLogsByCallerJob).to receive(:perform_later)

        caller_id.save
      end

      it 'splits job into fg and bg (for more responsive UI – see #2057)' do
        expect(UpdateCtiLogsByCallerJob).to receive(:perform_now).with(phone, limit: 20)
        expect(UpdateCtiLogsByCallerJob).to receive(:perform_later).with(phone, limit: 40, offset: 20)

        caller_id.save
      end

      it 'skips jobs on import_mode true' do
        Setting.set('import_mode', true)

        expect(UpdateCtiLogsByCallerJob).not_to receive(:perform_now)
        expect(UpdateCtiLogsByCallerJob).not_to receive(:perform_later)

        caller_id.save
      end
    end

    describe 'on destruction' do
      before { caller_id.save }

      it 'orphans CTI Logs from same number (via UpdateCtiLogsByCallerJob)' do
        expect(UpdateCtiLogsByCallerJob).to receive(:perform_later).with(phone)

        caller_id.destroy
      end
    end
  end
end
