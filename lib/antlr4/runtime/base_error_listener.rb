require '../antlr4/antlr_error_listener'

class BaseErrorListener < ANTLRErrorListener
  def syntax_error(_recognizer, _offending_symbol, _line, _char_position_in_line, _msg, _e); end

  def report_ambiguity(_recognizer, _dfa, _start_index, _stop_index, _exact, _ambig_ilts, _configs); end

  def report_attempting_full_context(_recognizer, _dfa, _start_index, _stop_index, _conflicting_alts, _configs); end

  def report_context_sensitivity(_recognizer, _dfa, _start_index, _stop_index, _prediction, _configs); end
end
