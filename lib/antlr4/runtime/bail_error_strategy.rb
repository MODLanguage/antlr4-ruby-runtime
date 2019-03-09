require '../antlr4/default_error_strategy'

class BailErrorStrategy < DefaultErrorStrategy
  def recover(recognizer, e)
    context = recognizer.getContext
    until context.nil?
      context = context.get_parent
      context.exception = e
    end

    raise ParseCancellationException(e)
  end

  def recover_in_line(recognizer)
    e = InputMismatchException.new recognizer
    context = recognizer.getContext
    until context.nil?
      context = context.get_parent
      context.exception = e
    end

    raise ParseCancellationException(e)
  end

  def sync(recognizer); end
end
