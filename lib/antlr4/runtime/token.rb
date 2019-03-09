require '../antlr4/int_stream'

class Token
  INVALID_TYPE = 0
  EPSILON = -2
  MIN_USER_TOKEN_TYPE = 1
  EOF = IntStream::EOF
  DEFAULT_CHANNEL = 0
  HIDDEN_CHANNEL = 1
  MIN_USER_CHANNEL_VALUE = 2
end
