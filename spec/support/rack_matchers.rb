RSpec::Matchers.define :match_response do |expected|
  match do |actual|
    %i(status header body).each do |attr|
      expect(actual.send(attr)).to eq(expected.send(attr))
    end
  end
end
