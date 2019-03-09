require '../antlr4/atn_config_set'

class OrderedATNConfigSet < ATNConfigSet
  class LexerConfigHashSet < AbstractConfigHashSet
    def initialize
      super(ObjectEqualityComparator.instance)
    end
  end

  def initialize
    super
    @config_lookup = LexerConfigHashSet.new
  end
end
