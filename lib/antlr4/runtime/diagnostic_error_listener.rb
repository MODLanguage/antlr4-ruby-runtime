class DiagnosticErrorListener < BaseErrorListener
  def initialize(exact_only = true)
    @exact_only = exact_only
  end

  def report_ambiguity(recognizer, dfa, start_index, stop_index, exact, ambig_alts, configs)
    return if @exact_only && !exact

    format = "reportAmbiguity d=%s: ambig_alts=%s, input='%s'"
    decision = decision_description(recognizer, dfa)
    conflicting_alts = conflicting_alts(ambig_alts, configs)
    text = recognizer.getTokenStream.text(Interval.of(start_index, stop_index))
    message = String.format(format, decision, conflicting_alts, text)
    recognizer.notify_error_listeners(message)
  end

  def report_attempting_full_context(recognizer, dfa, start_index, stop_index, _conflicting_alts, _configs)
    format = "reportAttemptingFullContext d=%s, input='%s'"
    decision = decision_description(recognizer, dfa)
    text = recognizer.getTokenStream.text(Interval.of(start_index, stop_index))
    message = String.format(format, decision, text)
    recognizer.notify_error_listeners(message)
  end

  def report_context_sensitivity(recognizer, dfa, start_index, stop_index, _prediction, _configs)
    format = "reportContextSensitivity d=%s, input='%s'"
    decision = decision_description(recognizer, dfa)
    text = recognizer.getTokenStream.text(Interval.of(start_index, stop_index))
    message = String.format(format, decision, text)
    recognizer.notify_error_listeners(message)
  end

  def decision_description(recognizer, dfa)
    decision = dfa.decision
    rule_index = dfa.atn_start_state.rule_index

    rule_names = recognizer.rule_names
    return decision.to_s if rule_index < 0 || rule_index >= rule_names.length

    rule_name = rule_names[rule_index]
    return decision.to_s if rule_name.nil? || rule_name.empty?

    String.format('%d (%s)', decision, rule_name)
  end

  def conflicting_alts(reported_alts, configs)
    return reported_alts unless reported_alts.nil?

    result = BitSet.new
    configs.each do |config|
      result.set(config.alt)
    end

    result
  end
end
