shared_examples "a queue" do
  let(:message) { double "Message", body: "uhuh" }
  let(:client) { double "ClientObject" }
  let(:name) { "venues queue" }
  subject do
    described_class.new client, name
  end

  # Poller object handles this
  it { should respond_to :receive }
  it { should respond_to :push }
  it { should respond_to :pop }
  it { should respond_to :peek }

  describe "peek" do
    before do
      not_for_null do
        client.stub queue: queue_object_with_message
      end
    end

    it "should take options and return an array" do
      subject.peek(option: true).should be_an Array
    end
  end

  describe "pop" do
    describe "with messages" do
      before do
        not_for_null do
          client.stub queue: queue_object_with_message
        end
      end

      it "should simply return a message" do
        not_for_null do
          subject.pop.should be_a Queuel::IronMq::Message
        end
      end

      it "should delete after bolck" do
        not_for_null do
          message.should_receive(:delete)
          subject.pop { |m| m }
        end
      end
    end
  end

  describe "with nil message" do
    before do
      not_for_null do
        client.stub queue: queue_object_with_nil_message
      end
    end

    it "should simply return a message" do
      subject.pop.should == nil
    end

    it "should delete after bolck" do
      subject.pop { |m| m } # basically, don't error
    end
  end
end
