# frozen_string_literal: true
require 'spec_helper'

module TL1
  describe Command do
    let(:rtrv_inv_output_format) do
      [
        '<aid>,<aidtype>',
        [
          'NAME=<name>',
          'PEC=<pec>',
          'CLEI=<clei>',
          'FNAME=<fname>',
          'SER=<ser>',
          'HWREV=<hwrev>',
          'FW=<fw>',
          'MFGDAT=<mfgdat>',
          'MFGLOCN=<mfglocn>',
          'TSTDAT=<tstdat>',
          'TSTLOCN=<tstlocn>',
          'WAVELENGTH=<wavelength>',
          'WAVELENGTHMIN=<wavelengthmin>',
          'WAVELENGTHMAX=<wavelengthmax>',
          'WAVELENGTHSPACING=<wavelengthspacing>',
          'REACH=<reach>',
          'MINBR=<minbr>',
          'MAXBR=<maxbr>',
          'NOMBR=<nombr>',
          'ENCODING=<encoding>',
          'CONNTYPE=<conntype>',
          'VENDORNAME=<vendorname>',
          'VENDORPN=<vendorpn>',
          'VENDOROUI=<vendoroui>',
          'TXFAULTIMP=<txfaultimp>',
          'TXDISABLEIMP=<txdisableimp>',
          'LOSIMP=<losimp>',
          'DDIAGIMP=<ddiagimp>',
          'MEDIA=<media>',
          'USI=<usi>',
          'TEMPHT=<tempht>',
          'TEMPHTS=<temphts>'
        ].join(',')
      ].join(':').freeze
    end

    let(:cmd) { TL1::Command.new(input_format, output_format) }

    describe '#input' do
      it 'appends a semicolon to the input message' do
        command = Command.new('EXAMPLE', '')
        expect(command.input).to eq 'EXAMPLE;'
      end
    end # describe '#input' do

    describe '#record_sources' do
      context 'output message with escaped quoted strings' do
        let(:input_format) { 'RTRV-ALM-ALL-TEST' }

        let(:output_format) do
          '<aid>,<aidtype>:'\
          '<conddescr>,<aiddet>,<obsdbhvr>,<exptdbhvr>:'\
          '<dgntype>,<tblislt>'
        end

        let(:output) do
          <<~'EOF'
            RTRV-ALM-ALL;

               bti7200hoge 17-09-06 11:45:28
            M  100 COMPLD
               "XFP-11-12-3,EQPT:\"XFP missing.\",,,:,"
               "XFP-11-12-4,EQPT:\"XFP missing.\",,,:,"
               "TPR-11-13-4,XCVR:\"Loss of signal.\",,,:,"
            ;
            BTI7000>
          EOF
        end

        it 'parses the escapes' do
          record_sources = [
            'XFP-11-12-3,EQPT:"XFP missing.",,,:,',
            'XFP-11-12-4,EQPT:"XFP missing.",,,:,',
            'TPR-11-13-4,XCVR:"Loss of signal.",,,:,'
          ]

          expect(cmd.record_sources(output)).to eq record_sources
        end
      end # context 'output message with quoted strings' do

      context 'output messages with continuation' do
        let(:input_format) { 'RTRV-INV' }
        let(:output_format) { rtrv_inv_output_format }

        let(:output) do
          <<~'END'
            IP 100
            <

               bti7200hoge 17-09-12 12:48:35
            M  100 COMPLD
               "MS-1,EQPT:NAME=MS7200,PEC=11111111,CLEI=UNKNOWN,FNAME=\"Main Shelf 7200\",SER=\"2222222222\",HWREV=\"A\",MFGDAT=\"2017-09-10\",MFGLOCN=33,TSTDAT=2017-09-11,TSTLOCN=19,USI=N/A,"
            >

               bti7200hoge 17-09-12 12:48:35
            M  100 COMPLD
               "XFP-1-9-3,EQPT:PEC=44444444444,SER=\"5555555\",HWREV=\"66\",MFGDAT=\"2017-09-12\",WAVELENGTH=1010.10,REACH=77,MINBR=8888,MAXBR=99999,ENCODING=UNKNOWN,CONNTYPE=LC,VENDORNAME=\"ACME CORP.\",VENDORPN=\"AAAAAAAAAAAAAAA\",VENDOROUI=\"BBBBBB\",TXFAULTIMP=Y,TXDISABLEIMP=Y,LOSIMP=Y,DDIAGIMP=Y,MEDIA=OPTICAL,USI=N/A,"
            ;
          END
        end

        let(:record_sources) do
          [
            'MS-1,EQPT:NAME=MS7200,PEC=11111111,CLEI=UNKNOWN,FNAME="Main Shelf 7200",SER="2222222222",HWREV="A",MFGDAT="2017-09-10",MFGLOCN=33,TSTDAT=2017-09-11,TSTLOCN=19,USI=N/A,',
            'XFP-1-9-3,EQPT:PEC=44444444444,SER="5555555",HWREV="66",MFGDAT="2017-09-12",WAVELENGTH=1010.10,REACH=77,MINBR=8888,MAXBR=99999,ENCODING=UNKNOWN,CONNTYPE=LC,VENDORNAME="ACME CORP.",VENDORPN="AAAAAAAAAAAAAAA",VENDOROUI="BBBBBB",TXFAULTIMP=Y,TXDISABLEIMP=Y,LOSIMP=Y,DDIAGIMP=Y,MEDIA=OPTICAL,USI=N/A,'
          ]
        end

        it 'returns the records in the continuations' do
          observed = cmd.record_sources(output)
          expected = record_sources

          expect(observed.size).to eq expected.size
          expect(observed).to eq record_sources
        end
      end # context 'output messages with continuation' do
    end # describe '#record_sources' do

    describe '#parse_output' do
      context 'output with quoted strings (RTRV-ALM-ALL)' do
        let(:input_format) { 'RTRV-ALM-ALL' }

        let(:output_format) do
          '<aid>,<aidtype>:'\
          '<ntfcncde>,<condtype>,<srveff>,<ocrdat>,<ocrtim>,<locn>,<dirn>,<tmper>:'\
          '<conddescr>,<aiddet>,<obsdbhvr>,<exptdbhvr>:'\
          '<dgntype>,<tblislt>'
        end

        context 'quoted strings' do
          let(:output) do
            <<~'EOF'
              RTRV-ALM-ALL;

                 bti7200hoge 17-09-06 11:45:28
              M  100 COMPLD
                 "XFP-11-12-3,EQPT:CR,REPLUNITMISS,SA,08-16,04-04-05,NEND,,:\"XFP missing.\",,,:,"
                 "XFP-11-12-4,EQPT:CR,REPLUNITMISS,SA,08-16,04-04-05,NEND,,:\"XFP missing.\",,,:,"
                 "TPR-11-13-4,XCVR:CR,LOS,SA,08-16,04-04-01,NEND,,:\"Loss of signal.\",,,:,"
              ;
              BTI7000>
            EOF
          end

          it 'parses records' do
            observed = cmd.parse_output(output)
            expect(observed.size).to eq 3
            expect(observed.last[:conddescr]).to eq 'Loss of signal.'
          end
        end # context 'quoted strings' do

        context 'quoted strings in keyword variables' do
          let(:input_format) { 'RTRV-INV' }
          let(:output_format) { rtrv_inv_output_format }

          let(:output) do
            <<~'END'
              IP 100
              <

                 bti7200hoge 17-09-12 12:48:35
              M  100 COMPLD
                 "MS-1,EQPT:NAME=MS7200,PEC=11111111,CLEI=UNKNOWN,FNAME=\"Main Shelf 7200\",SER=\"2222222222\",HWREV=\"0\",MFGDAT=\"2017-09-12\",MFGLOCN=99,TSTDAT=2017-09-12,TSTLOCN=88,USI=N/A,"
              ;
            END
          end

          it 'unwraps the quoted string' do
            fname = cmd.parse_output(output).first[:fname]
            expect(fname).to eq 'Main Shelf 7200'
          end
        end # context 'quoted strings in keyword variables' do

        context 'quoted strings containing delimiters' do
          let(:output) do
            <<~'END'
              RTRV-ALM-ALL;

                 bti7200hoge 17-09-06 11:45:28
              M  100 COMPLD
                 "XFP-11-12-3,EQPT:CR,REPLUNITMISS,SA,08-16,04-04-05,NEND,,:\"XFP: missing.\",,,:,"
                 "TPR-11-13-4,XCVR:CR,LOS,SA,08-16,04-04-01,NEND,,:\"Loss, of signal.\",,,:,"
              ;
              BTI7000>
            END
          end

          it 'parses records' do
            observed = cmd.parse_output(output)
            expect(observed.size).to eq 2
            expect(observed.last[:conddescr]).to eq 'Loss, of signal.'
            expect(observed.first[:conddescr]).to eq 'XFP: missing.'
          end
        end # context 'quoted strings containing delimiters' do
      end # context 'output with quoted strings (RTRV-ALM-ALL)' do

      context 'RTRV-EQPT' do
        let(:input_format) { 'RTRV-EQPT' }

        let(:output_format) do
          '<aid>:<type>:ID=<id>,C1=<custom1>,C2=<custom2>,C3=<custom3>:pst,sst'
        end

        let(:output) do
          <<~EOF
            RTRV-EQPT;

               bti7200hoge 17-08-31 16:29:53
            M  100 COMPLD
               "AA-1:11111111::IS-NR,"
               "AAA-1-1:11111112::IS-NR,"
               "AAA-1-2:11111113::IS-NR,"
               "AAA-1-8:11111114::IS-NR,"
               "AAA-1-9:11111115::IS-NR,"
               "AAA-1-10:11111116::IS-NR,"
               "AA-11:11111117::IS-NR,"
               "AAA-11-1:11111118::IS-NR,"
               "AAA-11-17:11111119::IS-NR,"
               "AAAAA-0-1:11111121:C2=blah:,"
               "AAAAA-0-2:11111122::,"
            ;
            BTI7000>
          EOF
        end

        it 'parses an output message into an array of record' do
          observed = cmd.parse_output(output)

          first = { aid: 'AA-1', type: '11111111', pst: 'IS-NR', sst: '' }
          last = { aid: 'AAAAA-0-2', type: '11111122', pst: '', sst: '' }

          expect(observed.size).to eq 11
          expect(observed.first).to eq first
          expect(observed.last).to eq last
          expect(observed[-2][:custom2]).to eq 'blah'

          observed.each do |record|
            expect(record.fetch(:sst)).to eq ''
          end
        end
      end # context 'RTRV-EQPT' do
    end # describe '#parse_output' do
  end # describe Command do
end # module TL1
