module Antlr4::Runtime

  class NoViableAltException < RecognitionException
    attr_accessor :dead_end_configs
    attr_accessor :start_token
  end
end