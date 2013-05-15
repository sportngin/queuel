module Queuel
  module BaseKlass
    def module_names
      self.to_s.split("::")[0..-2].join("::")
    end

    def const_with_nesting(other_name)
      Object.module_eval("#{module_names}::#{other_name}", __FILE__, __LINE__)
    end
  end
end
