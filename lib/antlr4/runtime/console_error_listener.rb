require '../antlr4/base_error_listener'
require 'singleton'

class ConsoleErrorListener < BaseErrorListener
  include Singleton

  def syntaxError(_recognizer, _offending_symbol, line, char_position_in_line, msg, _e)
    STDERR.puts 'line ' << line.to_s << ':' << char_position_in_line.to_s << ' ' << msg.to_s << ''
  end
end
