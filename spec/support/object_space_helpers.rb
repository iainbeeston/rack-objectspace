module ObjectSpaceHelpers
  def object_space(object_data)
    FakeObjectSpace.new(object_data)
  end

  private

  class FakeObjectSpace
    def initialize(object_data)
      @object_data = object_data
    end

    def trace_object_allocations_start
    end

    def dump_all(output:)
      output << @object_data
    end
  end
end
