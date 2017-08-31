shared_examples "a poller" do
  let(:message) { double "message" }
  let(:queue) { double "Queue", peek: [], approximate_number_of_messages: 0 }
  let(:block) { lambda{ |m| true } }
  let(:thread_count) { 1 }
  let(:options) { {} }

  subject do
    described_class.new queue, block, options, thread_count
  end

  it { should respond_to :poll }

  describe "profiling", perf: true do
    let(:magnitude) { 3000 }

    before do
      message.stub delete: true
      subject.stub quit_on_empty?: true
      subject.stub(:pop_new_message).and_return(*([message]*magnitude), nil)
    end

    describe "with 1 thread" do
      let(:thread_count) { 1 }
      before do
        queue.stub(:peek).and_return *([message] * magnitude), nil
        queue.stub(:approximate_number_of_messages).and_return *([message] * magnitude).map{|m| m.size}, 0
      end

      it "can poll" do
        not_for_null do
          subject.poll
        end
      end
    end

    describe "with 3 threads" do
      let(:thread_count) { 3 }
      before do
        queue.stub(:peek).and_return *([message, message, message] * (magnitude/3)), nil
        queue.stub(:approximate_number_of_messages).and_return *([message, message, message] * (magnitude/3)).map{|m| m.size}, 0
      end

      it "can poll" do
        not_for_null do
          subject.poll
        end
      end
    end
  end

  describe "limited loops" do
    describe "with 2 yields, one nil" do
      before do
        subject.stub quit_on_empty?: true
        queue.stub(:peek).and_return [message], nil
        subject.stub(:pop_new_message).and_return(message, nil)

      end

      it "can poll" do
        not_for_null do
          queue.stub(:approximate_number_of_messages).and_return 1, 0
          queue.stub(:max_pool_tasks).and_return nil
          block.should_receive(:call).once.and_return true
          message.should_receive(:delete)
          subject.poll
        end
      end

      it "can poll with poll limit" do
        not_for_null do
          queue.stub(:peek).and_return [message, message], [message], nil
          queue.stub(:approximate_number_of_messages).and_return 2, 1, 0
          queue.stub(:max_pool_tasks).and_return 1
          block.should_receive(:call).once.and_return true
          message.should_receive(:delete)
          subject.should_receive(:increment_pool_task_count).at_least(1).times
          subject.should_receive(:decrement_pool_task_count).once
          subject.send :process_off_peek
        end
      end
    end
  end


end
