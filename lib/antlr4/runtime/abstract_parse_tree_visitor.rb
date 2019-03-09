class AbstractParseTreeVisitor
  def visit(tree)
    tree.accept(self)
  end

  def visit_children(node)
    result = default_result
    n = node.child_count
    i = 0
    while i < n
      break unless should_visit_next_child(node, result)

      c = node.child(i)
      child_result = c.accept(this)
      result = aggregate_result(result, child_result)
      i += 1
    end

    result
  end

  def visit_terminal(_node)
    default_result
  end

  def visit_error_node(_node)
    default_result
  end

  def default_result
    nil
  end

  def aggregate_result(_aggregate, next_result)
    next_result
  end

  def should_visit_next_child(_node, _current_result)
    true
  end
end