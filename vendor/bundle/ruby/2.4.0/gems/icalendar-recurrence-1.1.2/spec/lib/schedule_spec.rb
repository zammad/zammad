require 'spec_helper'

describe Icalendar::Recurrence::Schedule do
  describe "#occurrences_between" do
    let(:example_occurrence) do
      daily_event = example_event :daily
      schedule = Schedule.new(daily_event)
      schedule.occurrences_between(Date.parse("2014-02-01"), Date.parse("2014-03-01")).first
    end

    it "returns object that responds to start_time and end_time" do
      expect(example_occurrence).to respond_to :start_time
      expect(example_occurrence).to respond_to :end_time
    end

    context "timezoned event" do
      let(:example_occurrence) do
        timezoned_event = example_event :first_saturday_of_month
        schedule = Schedule.new(timezoned_event)
        example_occurrence = schedule.occurrences_between(Date.parse("2014-02-01"), Date.parse("2014-03-01")).first
      end

      it "#occurrences_between return object that responds to #start_time and #end_time (timezoned example)" do
        expect(example_occurrence).to respond_to :start_time
        expect(example_occurrence).to respond_to :end_time
      end
    end
  end

  describe "#all_occurrences" do
    let(:example_occurrences) do
      weekly_event = example_event :weekly_with_count
      schedule = Schedule.new(weekly_event)
      schedule.all_occurrences
    end

    let(:example_occurrence) { example_occurrences.first }

    it "returns object that responds to start_time and end_time" do
      expect(example_occurrence).to respond_to :start_time
      expect(example_occurrence).to respond_to :end_time
    end

    it "returns all occurrences" do
      expect(example_occurrences.count).to eq(151)
    end
  end

  context "given an event without an end time" do
    let(:schedule) do
      weekly_event = example_event :weekly_with_count # has 1 hour duration
      allow(weekly_event).to receive(:end).and_return(nil)
      Schedule.new(weekly_event)
    end

    it "calculates end time based on start_time and duration" do
      expect(schedule.end_time).to eq(schedule.start_time + 1.hour)
    end
  end

end
