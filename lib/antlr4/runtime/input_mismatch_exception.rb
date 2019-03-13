require 'antlr4/runtime/recognition_exception'

module Antlr4::Runtime

  class InputMismatchException < RecognitionException
    def self.create(recog, state = nil)
      result = InputMismatchException.new

      result.offending_state = -1
      result.context = recog._ctx
      result.input = recog._input
      result.recognizer = recog
      result.offending_state = recog._state_number unless recog.nil?

      result.offending_token = recog.current_token unless recog.nil?
      result.offending_state = state unless state.nil?
      result
    end
  end
end