# Rush (= Ruby Scheme Interpreter)

def read_input
  loop do
    print 'rush >> '
    input = gets
    puts input
  end
end

def tokenize(s)
  s.gsub(/[()]/, ' \0 ').split
end

def read_tokens(tokens)
  raise SyntaxError, 'unexpected EOF while reading' if tokens.length == 0

  case token = tokens.shift
  when '('
    l = []
    while tokens[0] != ')'
      l.push read_tokens(tokens)
    end
    tokens.shift
    l
  when ')'
    raise SyntaxError, 'unexpected ")"'
  else
    token
  end
end

def atom(token)
  begin
    Integer(token)
  rescue ArgumentError
    begin
      Float(token)
    rescue ArgumentError
      token.to_sym
    end
  end
end

if __FILE__ == $0
  read_input
end
