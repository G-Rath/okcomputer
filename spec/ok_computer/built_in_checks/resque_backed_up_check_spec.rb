require "rails_helper"

# Stubbing the constant out; will exist in apps which have Resque loaded
class Resque; end

module OkComputer
  describe ResqueBackedUpCheck do
    let(:queue) { "queue name" }
    let(:threshold) { 100 }

    subject { ResqueBackedUpCheck.new queue, threshold }

    it "is a Check" do
      expect(subject).to be_a Check
    end

    context ".new(queue, threshold)" do
      it "accepts a queue name and a threshold to consider backed up" do
        expect(subject.queue).to eq(queue)
        expect(subject.threshold).to eq(threshold)
      end

      it "coerces the threshold parameter into an integer" do
        threshold = "123"
        expect(ResqueBackedUpCheck.new(queue, threshold).threshold).to eq(123)
      end
    end

    context "#check" do
      let(:status) { "status text" }

      context "with the count less than the threshold" do
        before do
          allow(subject).to receive(:size) { threshold - 1 }
        end

        it { is_expected.to be_successful_check }
        it { is_expected.to have_message "Resque queue '#{queue}' at reasonable level (#{subject.size})" }
      end

      context "with the count equal to the threshold" do
        before do
          allow(subject).to receive(:size) { threshold }
        end

        it { is_expected.to be_successful_check }
        it { is_expected.to have_message "Resque queue '#{queue}' at reasonable level (#{subject.size})" }
      end

      context "with a count greater than the threshold" do
        before do
          allow(subject).to receive(:size) { threshold + 1 }
        end

        it { is_expected.not_to be_successful_check }
        it { is_expected.to have_message "Resque queue '#{subject.queue}' is #{subject.size - subject.threshold} over threshold! (#{subject.size})" }
      end
    end

    context "#size" do
      let(:size) { 123 }

      it "defers to Resque for the job count" do
        expect(Resque).to receive(:size).with(subject.queue) { size }
        expect(subject.size).to eq(size)
      end
    end
  end
end
