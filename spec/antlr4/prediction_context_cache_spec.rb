require 'antlr4/runtime/prediction_context_cache'

RSpec.describe Antlr4::Runtime do

  it "can create a PredictionContextCache" do
    cache = Antlr4::Runtime::PredictionContextCache.new

    expect(cache).not_to be nil
  end
end
