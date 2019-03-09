require 'weakref'
require '../antlr4/console_error_listener'
require '../antlr4/proxy_error_listener'

class Recognizer
  EOF = -1

  attr_accessor :_interp
  attr_accessor :_state_number

  def initialize
    @token_type_map_cache = []
    @rule_index_map_cache = []
    @_listeners = []
    @_listeners << ConsoleErrorListener.instance
    @_interp = nil
    @_state_number = -1
  end

  def get_vocabulary
    VocabularyImpl.from_token_names(token_names)
  end

  def token_names
    nil
  end

  def rule_names
    nil
  end

  def get_token_type_map
    vocab = get_vocabulary
    result = @token_type_map_cache[vocab]
    if result.nil?
      result = {}
      i = 0
      while i <= getATN.max_token_type
        literal_name = vocab.literal_name(i)
        result[literal_name] = i unless literal_name.nil?

        symbolic_name = vocab.symbolic_name(i)
        result[symbolic_name] = i unless symbolic_name.nil?
        i += 1
      end

      result['EOF'] = Token::EOF
      @token_type_map_cache[vocab] = result
    end

    result
  end

  def get_rule_index_map
    if rule_names.nil?
      raise UnsupportedOperationException, 'The current recognizer does not provide a list of rule names.'
    end

    result = @rule_index_map_cache[rule_names]
    if result.nil?
      result = Utils.toMap(rule_names)
      @rule_index_map_cache[rule_names] = result
    end

    result
  end

  def get_token_type(token_name)
    ttype = get_token_type_map[token_name]
    return ttype unless ttype.nil?

    Token::INVALID_TYPE
  end

  def get_serialized_atn
    raise UnsupportedOperationException, 'there is no serialized ATN'
  end

  def parse_info
    nil
  end

  def error_header(e)
    line = e.getOffendingToken.line
    charPositionInLine = e.getOffendingToken.char_position_in_line
    'line ' + line + ':' + charPositionInLine
  end

  def token_error_display(t)
    return '<no token>' if t.nil?

    s = t.text
    if s.nil?
      s = if t.type == Token::EOF
            '<EOF>'
          else
            '<' + t.type + '>'
          end
    end
    s = s.tr_s!("\n", '\\n')
    s = s.tr_s!("\r", '\\r')
    s = s.tr_s!("\t", '\\t')
    "'" + s + "'"
  end

  def add_error_listener(listener)
    raise NullPointerException, 'listener cannot be nil.' if listener.nil?

    @_listeners << listener
  end

  def remove_error_listener(listener)
    @_listeners.delete(listener)
  end

  def remove_error_listeners
    @_listeners.clear
  end

  def error_listener_dispatch
    ProxyErrorListener.new(@_listeners)
  end

  def sempred(_localctx, _rule_index, _action_index)
    true
  end

  def precpred(_localctx, _precedence)
    true
  end

  def action(_localctx, _rule_index, _action_index)
  end
end
