module Queuel
  class Hash < ::Hash
    def self.new(*args, &block)
      if args.first.is_a?(::Hash)
        allocate.send(:initialize).replace(args.first)
      else
        super *args, &block
      end
    end

    def partition(&block)
      if block_given?
        one, two = super &block
        [Hash[one], Hash[two]]
      else
        super &block
      end
    end
  end
end
