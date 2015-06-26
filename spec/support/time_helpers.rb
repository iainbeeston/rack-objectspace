module TimeHelpers
  def time(time)
    FakeTime.new(time)
  end

  private

  class FakeTime
    def initialize(time)
      @time = time
    end

    def now
      @time
    end
  end
end
