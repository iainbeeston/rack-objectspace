require 'spec_helper'
require 'support/rack_helpers'
require 'support/object_space_helpers'
require 'support/file_store_helpers'
require 'support/rack_matchers'
require 'rack/mock'
require 'securerandom'

describe Rack::Profiler do
  include RackHelpers
  include ObjectSpaceHelpers
  include FileStoreHelpers

  let(:env) { [418, { 'Content-Type' => 'text/plain', 'Content-Length' => '12' }, ["I'm a teapot"]] }
  let(:app) { ->(_) { env } }
  let(:store) { Hash.new }
  let(:middleware) { described_class.new(app, store: store, async: false, object_space: objects) }
  let(:server) { rack(middleware) }

  let(:object_data) do
    <<-STR
      {"address":"0x7f930a8203a8", "type":"ARRAY"}
    STR
  end
  let(:objects) { object_space(object_data) }

  describe '#call' do
    it 'does not modify the response from the app' do
      expect(request(server, '/')).to match_response(response(env))
    end

    context 'with real data' do
      let(:object_data) do
        <<-STR
          {"address":"0x7f930a820650", "type":"ARRAY"}
          {"address":"0x7f930a8206c8", "type":"OBJECT"}
        STR
      end
      let(:store_id) { SecureRandom.uuid }
      let(:store) { file_store(store_id) }

      it 'saves every object in the object space to the store' do
        expect {
          request(server, '/')
        }.to change {
          file_store_keys(store_id).map { |k| store[k] }
        }.from([]).to([{ 'type' => 'ARRAY' }, { 'type' => 'OBJECT' }])
      end
    end
  end

  describe '#request_id' do
    it 'returns a unique string every time' do
      expect(middleware.request_id).to_not eq(middleware.request_id)
    end
  end

  describe '#store_object' do
    it 'stores the hash by the address property' do
      expect {
        middleware.store_object('key', 'address' => '0x7f930a820010', 'type' => 'OBJECT')
      }.to change {
        store['key-0x7f930a820010']
      }.from(nil).to('type' => 'OBJECT')
    end

    it 'stores nothing if there is no address property' do
      expect {
        middleware.store_object('key', 'type' => 'OBJECT')
      }.to_not change {
        store.keys
      }.from([])
    end
  end

  describe '#parse_dump' do
    it 'parses the input io stream and calls run for each line (parsed as json)' do
      json = <<-STR
        {"address":"0x7f930a8203a8", "type":"ARRAY"}
        {"address":"0x7f930a820420", "type":"ARRAY"}
      STR
      io = StringIO.new(json)
      calls = []
      processor = ->(id, obj) { calls << [id, obj] }
      middleware.parse_dump(input: io, key: 'key', run: processor)
      expect(calls).to eq([['key', { 'address' => '0x7f930a8203a8', 'type' => 'ARRAY' } ],
                           ['key', { 'address' => '0x7f930a820420', 'type' => 'ARRAY' } ]])
    end
  end
end
