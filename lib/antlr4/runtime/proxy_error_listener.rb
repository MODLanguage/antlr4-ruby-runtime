class ProxyErrorListener
  def initialize(delegates)
    raise StandardError, 'delegates is nil' if delegates.nil?

    @delegates = delegates
  end

  def syntax_error(recognizer, offending_symbol, line, char_position_in_line, msg, e)
    @delegates.each do |listener|
      listener.syntax_error(recognizer, offending_symbol, line, char_position_in_line, msg, e)
    end
  end

  def report_ambiguity(recognizer, dfa, start_index, stop_index, exact, ambig_alts, configs)
    @delegates.each do |listener|
      listener.report_ambiguity(recognizer, dfa, start_index, stop_index, exact, ambig_alts, configs)
    end
  end

  def report_attempting_full_context(recognizer, dfa, start_index, stop_index, conflicting_alts, configs)
    @delegates.each do |listener|
      listener.report_attempting_full_context(recognizer, dfa, start_index, stop_index, conflicting_alts, configs)
    end
  end

  def report_context_sensitivity(recognizer, dfa, start_index, stop_index, prediction, configs)
    @delegates.each do |listener|
      listener.report_context_sensitivity(recognizer, dfa, start_index, stop_index, prediction, configs)
    end
  end
end
