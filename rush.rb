# Rush (= Ruby Scheme Interpreter)

def read_input
  loop do
    print 'rush >> '
    input = gets

    break if input == "quit\n"

    print parse(input), "\n"
  end
  print "bye...\n"
end

def read(s)
  read_tokens tokenize(s)
end
alias :parse :read

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
    atom token
  end
end

def atom(token)
  type_casts = [
    lambda { |arg| Integer arg },
    lambda { |arg| Float arg },
    lambda { |arg| arg.to_sym },
  ]

  begin
    type_casts.first.call(token)
  rescue ArgumentError
    # remove first element of type_casts
    # and retry this method
    type_casts.shift
    retry
  end
end

if __FILE__ == $0
  read_input
end
