require 'timeout'
module Queuel
  module Null
    class Poller < Base::Poller
      alias built_options options
    end
  end
end
