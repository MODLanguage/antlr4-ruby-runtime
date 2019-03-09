require '../antlr4/recognition_exception'

class InputMismatchException < RecognitionException
  def self.create(recog, state = nil)
    result = InputMismatchException.new

    result.offending_state = -1
    result.context = recog._ctx
    result.input = recog.input_stream
    result.recognizer = recog
    result.offending_state = recog.getState unless recog.nil?

    result.offending_token = recog.current_token unless recog.nil?
    result.offending_state = state unless state.nil?
    result
  end
end
