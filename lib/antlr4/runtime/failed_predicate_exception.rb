require '../antlr4/recognition_exception'

class FailedPredicateException < RecognitionException
  attr_reader :predicate
  attr_reader :predicate_index
  attr_reader :rule_index

  def initialize(recognizer, predicate = nil, message = nil)
    super(format_message(predicate, message))
    @recognizer = recognizer
    @input = recognizer.input_stream
    @context = recognizer._ctx

    s = recognizer._interp.atn.states.get(recognizer.getState)

    trans = s.transition(0)
    if trans.is_a? PredicateTransition
      @rule_index = trans.rule_index
      @predicate_index = trans.pred_index
    else
      @rule_index = 0
      @predicate_index = 0
    end

    @predicate = predicate
    @offending_token = recognizer.current_token
  end

  def format_message(predicate, message)
    message.nil? ? message : "failed predicate: {" + predicate + "}?"
  end
end
