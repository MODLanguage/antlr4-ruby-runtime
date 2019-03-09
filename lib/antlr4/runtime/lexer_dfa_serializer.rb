require '../antlr4/dfa_serializer'

class LexerDFASerializer < DFASerializer
  def initialize(dfa)
    init_from_vocabulary(dfa, VocabularyImpl::EMPTY_VOCABULARY)
  end

  def edge_label(i)
    "'" << i.to_s << "'"
  end
end
