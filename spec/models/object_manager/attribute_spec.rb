require 'rails_helper'

RSpec.describe ObjectManager::Attribute, type: :model do
  describe 'callbacks' do
    context 'for setting default values on local data options' do
      let(:subject) { described_class.new }

      context ':null' do
        it 'sets nil values to true' do
          expect { subject.validate }
            .to change { subject.data_option[:null] }.to(true)
        end

        it 'does not overwrite false values' do
          subject.data_option[:null] = false

          expect { subject.validate }
            .not_to change { subject.data_option[:null] }
        end
      end

      context ':maxlength' do
        context 'for data_type: select / tree_select / checkbox' do
          let(:subject) { described_class.new(data_type: 'select') }

          it 'sets nil values to 255' do
            expect { subject.validate }
              .to change { subject.data_option[:maxlength] }.to(255)
          end
        end
      end

      context ':nulloption' do
        context 'for data_type: select / tree_select / checkbox' do
          let(:subject) { described_class.new(data_type: 'select') }

          it 'sets nil values to true' do
            expect { subject.validate }
              .to change { subject.data_option[:nulloption] }.to(true)
          end

          it 'does not overwrite false values' do
            subject.data_option[:nulloption] = false

            expect { subject.validate }
              .not_to change { subject.data_option[:nulloption] }
          end
        end
      end
    end
  end
end
