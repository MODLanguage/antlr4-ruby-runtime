class ANTLRErrorStrategy
  def reset(_recognizer); end

  def recover_in_line(_recognizer); end

  def recover(_recognizer, _e); end

  def sync(_recognizer); end

  def in_error_recovery_mode(_recognizer); end

  def report_match(_recognizer); end

  def report_error(_recognizer, _e); end
end
