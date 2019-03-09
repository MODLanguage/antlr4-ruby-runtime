require '../antlr4/transition'

class AbstractPredicateTransition < Transition
  def initialize(target)
    super(target)
  end
end
