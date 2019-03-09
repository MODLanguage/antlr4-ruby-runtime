class ANTLRErrorListener
  def syntaxError(_recognizer, _offending_symbol, _line, _char_position_in_line, _msg, _e); end

  def reportAmbiguity(_recognizer, _dfa, _start_index, _stop_index, _exact, _ambig_alts, _configs); end

  def reportAttemptingFullContext(_recognizer, _dfa, _start_index, _stop_index, _conflicting_alts, _configs); end

  def reportContextSensitivity(_recognizer, _dfa, _start_index, _stop_index, _prediction, _configs); end
end
