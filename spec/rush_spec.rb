require 'spec_helper'
require './rush'

describe 'Rush' do
  describe '#read' do
    subject { read string }

    context 'just symbol' do
      let(:string) { "(hoge)" }

      it { is_expected.to eq [:hoge] }
    end

    context 'symbol & integer' do
      let(:string) { "(hoge (10))" }

      it { is_expected.to eq [:hoge, [10]] }
    end

    context 'symbol & integer & float' do
      let(:string) { "(hoge (10) 10.5)" }

      it { is_expected.to eq [:hoge, [10], 10.5] }
    end

    context 'like normal calculation' do
      let(:string) { "(+ 10 12 (* -5.5 8))" }

      it { is_expected.to eq [:+, 10, 12, [:*, -5.5, 8]] }
    end
  end

  describe '#parse (alias)' do
    subject { parse string }

    context do
      let(:string) { "(print (+ 10 12 (* -5.5 8)))" }

      it { is_expected.to eq [:print, [:+, 10, 12, [:*, -5.5, 8]]] }
    end
  end

  describe '#tokenize' do
    subject { tokenize string }

    context 'normal input' do
      let(:string) { '(hoge)' }

      it { is_expected.to eq ['(', 'hoge', ')'] }
    end

    context 'input with extra spaces' do
      let(:string) { '( hoge )' }

      it { is_expected.to eq ['(', 'hoge', ')'] }
    end

    context 'many ( & ), and extra spaces' do
      let(:string) { '( (haskell)((     (( () ruby' }

      it { is_expected.to eq ['(', '(', 'haskell', ')', '(', '(', '(', '(', '(', ')', 'ruby'] }
    end

    context 'other symbols' do
      let(:string) { ':^@$"%^' }

      it { is_expected.to eq [':^@$"%^' ] }
    end
  end

  describe '#read_tokens' do
    subject { read_tokens tokens }

    context 'just "(" and ")"' do
      let(:tokens) { ['(', ')'] }

      it { is_expected.to eq [] }
    end

    context '"(" and something and ")"' do
      let(:tokens) { ['(', '100', '3.14', 'hoge', '$%@&^', ')'] }

      it { is_expected.to eq [100, 3.14, :hoge, :"$%@&^"] }
    end

    context 'complex tokens' do
      let(:tokens) { ['(', '(', '100', ')', '(', 'ruby', '(', 'neko', ')', ')', '3.14', ')', 'ignored'] }

      it { is_expected.to eq [[100], [:ruby, [:neko]], 3.14] }
    end

    context 'raise Syntax Error' do
      context 'length == 0' do
        let(:tokens) { [] }

        it { expect { subject }.to raise_error(SyntaxError, "unexpected EOF while reading") }
      end

      context 'tokens just have "("' do
        let(:tokens) { [')'] }

        it { expect { subject }.to raise_error(SyntaxError, 'unexpected ")"') }
      end

      context 'tokens start ")"' do
        let(:tokens) { [')', '(', 'hoge', ')', ')'] }

        it { expect { subject }.to raise_error(SyntaxError, 'unexpected ")"') }
      end

      context 'start from "(" but not end with ")"' do
        let(:tokens) { ['(', 'hoge', 'fuga', '210'] }

        it { expect { subject }.to raise_error(SyntaxError, "unexpected EOF while reading") }
      end
    end
  end

  describe '#atom' do
    subject { atom token }

    context 'Integer' do
      context 'positive' do
        let(:token) { '10' }

        it { is_expected.to eq 10 }
      end

      context 'negative' do
        let(:token) { '-65525' }

        it { is_expected.to eq (-65525) }
      end
    end

    context 'Float' do
      context 'positive' do
        let(:token) { '10.37465' }

        it { is_expected.to eq 10.37465 }
      end

      context 'negative' do
        let(:token) { '-172.367' }

        it { is_expected.to eq (-172.367) }
      end
    end

    context 'Symbol' do
      context 'normal literals' do
        let(:token) { 'hoge' }

        it { is_expected.to eq :hoge }
      end

      context 'other symbols' do
        let(:token) { '$%@*$^' }

        it { is_expected.to eq :"$%@*$^" }
      end
    end
  end

  describe '#evaluate' do
    subject { evaluate exps }

    context 'just a Symbol' do
      let(:exps) { :hoge }

      it { is_expected.to eq :hoge }
    end

    context 'Single Depth Array calculation' do
      let(:exps) { [:+, 1, 2, 3] }

      it { is_expected.to eq 6 }
    end

    context 'Multi Depth Array calculation' do
      let(:exps) { [:+, 1, 2, [:*, 5, 10]] }

      it { is_expected.to eq 53 }
    end
  end
end
