class RecognitionException < StandardError
  attr_accessor :recognizer
  attr_accessor :context
  attr_accessor :offending_token
  attr_accessor :offending_state
  attr_accessor :input

  def expected_tokens
    unless @recognizer.nil?
      return @recognizer.getATN.expected_tokens(@offending_state, @context)
    end

    nil
  end
end
