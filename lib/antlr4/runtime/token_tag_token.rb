class TokenTagToken < CommonToken
  attr_reader :token_name
  attr_reader :label

  def initialize(token_name, type, label = nil)
    super(type)
    @token_name = token_name
    @label = label
  end

  def text
    return '<' + @label + ':' + @token_name + '>' unless @label.nil?

    '<' + @token_name + '>'
  end

  def to_s
    @token_name + ':' + @type
  end
end
