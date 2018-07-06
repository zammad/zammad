require 'rails_helper'

RSpec.describe Overview do

  context 'link generation' do

    it 'generates from name' do
      overview = create(:overview, name: 'Not Shown Admin 2')
      expect(overview.link).to eq('not_shown_admin_2')
    end

    it 'ensures uniquenes' do
      overview1, overview2, overview3 = create_list(:overview, 3, name: 'Übersicht')

      expect(overview1.link).not_to eq(overview2.link)
      expect(overview1.link).not_to eq(overview3.link)
      expect(overview2.link).not_to eq(overview3.link)
    end

    context 'given link' do

      it 'keeps on create' do
        overview = create(:overview, name: 'Übersicht', link: 'my_overview')
        expect(overview.link).to eq('my_overview')
      end

      it 'keeps on update' do
        overview = create(:overview, name: 'Übersicht')
        overview.update!(link: 'my_overview_2')
        expect(overview.link).to eq('my_overview_2')
      end
    end

    context 'URL save' do

      it 'handles umlauts' do
        overview = create(:overview, name: 'Übersicht')
        expect(overview.link).to eq('ubersicht')
      end

      it 'handles spaces' do
        overview = create(:overview, name: "   Meine  Übersicht   \n")
        expect(overview.link).to eq('meine_ubersicht')
      end

      it 'handles special chars' do
        overview = create(:overview, name: 'Д дФ ф')
        expect(overview.link).to match(/^\d{1,3}$/)
      end

      it 'removes special char fallback if possible' do
        overview = create(:overview, name: ' Д дФ ф abc ')
        expect(overview.link).to eq('abc')
      end
    end
  end

  describe '#rearrangement' do

    it 'rearranges prio of other overviews on prio change' do

      overview1 = create(:overview, prio: 1)
      overview2 = create(:overview, prio: 2)
      overview3 = create(:overview, prio: 3)

      overview2.update!(prio: 3)

      overviews = described_class.all.order(prio: :asc).pluck(:id)

      expect(overviews.first).to eq(overview1.id)
      expect(overviews.second).to eq(overview3.id)
      expect(overviews.third).to eq(overview2.id)
    end
  end
end
