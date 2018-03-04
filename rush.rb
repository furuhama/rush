# Rush (= Ruby Scheme Interpreter)

def read
  loop do
    print 'rush >> '
    input = gets
    puts input
  end
end

def tokenize(s)
  s.gsub(/[()]/, ' \0 ').split
end

if __FILE__ == $0
  read
end