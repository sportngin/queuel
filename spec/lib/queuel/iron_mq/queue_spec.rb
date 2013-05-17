require 'spec_helper'
module Queuel
  module IronMq
    describe Queue do
      let(:queue_object_with_message) { double "QueueObject", get: message, peek: [message] }
      let(:queue_object_with_nil_message) { double "QueueObject", get: nil, peek: nil }
      it_should_behave_like "a queue"
    end
  end
end
