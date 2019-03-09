require '../antlr4/terminal_node'

class TerminalNodeImpl < TerminalNode
  attr_accessor :symbol
  attr_accessor :parent

  def initialize(symbol)
    @symbol = symbol
  end

  def child(_i)
    nil
  end

  def payload
    @symbol
  end

  def source_interval
    return Interval.INVALID if @symbol.nil?

    token_index = @symbol.token_index
    Interval.new(token_index, token_index)
  end

  def child_count
    0
  end

  def accept(visitor)
    visitor.visit_terminal(self)
  end

  def text
    @symbol.text
  end

  def to_string_tree(_parser = nil)
    to_s
  end

  def to_s
    return '<EOF>' if @symbol.type == Token::EOF

    @symbol.text
  end
end
