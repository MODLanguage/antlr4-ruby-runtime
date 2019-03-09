require '../antlr4/atn'
require '../antlr4/atn_state'

atn = ATN.new(0, 100)

atn.next_tokens_ctx(ATNState.new, RuleContext.new)
atn.next_tokens(ATNState.new)
atn.add_state(ATNState.new)
atn.remove_state(ATNState.new)
atn.define_decision_state(DecisionState.new)