module Queuel
  module SNS
    class Message < Base::Message
      def raw_body
        encoded_body
      end
    end
  end
end
