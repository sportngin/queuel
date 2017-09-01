require 'spec_helper'
module Queuel
  module Null
    describe Queue do
      let(:message) { double "Message", body: "uhuh" }
      let(:client) { double "ClientObject" }
      let(:name) { "venues queue" }
      let(:null) { true }
      it_should_behave_like "a queue"
    end
  end
end
