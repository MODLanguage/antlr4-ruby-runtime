require '../antlr4/terminal_node_impl'

class ErrorNodeImpl < TerminalNodeImpl
  def initialize(token)
    super(token)
  end

  def accept(visitor)
    visitor.visit_error_node(self)
  end
end
