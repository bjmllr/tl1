# frozen_string_literal: true

require 'spec_helper'
require 'json'

module TL1
  describe OutputFormat do
    describe '.new' do
      let(:source) do
        '<aid>:'\
        '<type>:'\
        'ID=<id>,C1=<custom1>,C2=<custom2>,C3=<custom3>:'\
        '<pst>,<sst>'
      end

      let(:format) { OutputFormat.new(source) }

      it 'extracts an AST from a format string' do
        expected = AST::ColonSeparatedVariables.new(
          AST::Variable.new(:aid),
          AST::Variable.new(:type),
          AST::CommaSeparatedKeywordVariables.new(
            'ID' => AST::Variable.new(:id),
            'C1' => AST::Variable.new(:custom1),
            'C2' => AST::Variable.new(:custom2),
            'C3' => AST::Variable.new(:custom3)
          ),
          AST::CommaSeparatedVariables.new(
            AST::Variable.new(:pst),
            AST::Variable.new(:sst)
          )
        )

        expect(format.ast).to eq expected
      end

      it 'converts an AST to a JSON-like structure' do
        json = {
          node: 'ColonSeparatedVariables',
          fields: [
            { node: 'Variable', fields: :aid },
            { node: 'Variable', fields: :type },
            {
              node: 'CommaSeparatedKeywordVariables',
              fields: {
                'ID' => { node: 'Variable', fields: :id },
                'C1' => { node: 'Variable', fields: :custom1 },
                'C2' => { node: 'Variable', fields: :custom2 },
                'C3' => { node: 'Variable', fields: :custom3 }
              }
            },
            {
              node: 'CommaSeparatedVariables',
              fields: [
                { node: 'Variable', fields: :pst },
                { node: 'Variable', fields: :sst }
              ]
            }
          ]
        }

        expect(format.ast.as_json).to eq json
        expect(format.ast.as_json.to_json).to eq json.to_json
      end

      it 'round-trips an AST to and from JSON' do
        ast = TL1::OutputFormat.new(JSON.parse(format.ast.as_json.to_json)).ast
        expect(ast).to eq format.ast
      end

      it 'raises on mismatched literals' do
        format_source = '<from_aid>,<to_aid>::SERVICENAME=<service_name>'
        format = OutputFormat.new(format_source)
        expect { format.parse('asdf,asdf:ASDF:') }
          .to raise_error(/Message literal.*does not match/)
      end

      it 'ignores matching literals' do
        format_source = '<from_aid>,<to_aid>::SERVICENAME=<service_name>'
        format = OutputFormat.new(format_source)
        expected = { from_aid: 'asdf', to_aid: 'asdf' }
        expect(format.parse('asdf,asdf::')).to eq expected
      end
    end # describe '.new' do
  end # describe OutputFormat do
end # module TL1
