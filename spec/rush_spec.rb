require 'spec_helper'
require './rush'

describe 'Rush' do
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
      let(:token) { 10 }

      it { is_expected.to eq 10 }
    end

    context 'Float' do
      let(:token) { 10.0 }

      it { is_expected.to eq 10.0 }
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
end
