# frozen_string_literal: true

# rubocop: disable Metrics/ModuleLength
module TL1
  module Platforms
    module BTI
      ACT_USER = Command.new('ACT-USER::<username>:::<password>')
      CANC_USER = Command.new('CANC-USER::<username>')

      RTRV_EQPT_ALL = Command.new(
        'RTRV-EQPT',
        '<aid>:<type>:ID=<id>,C1=<custom1>,C2=<custom2>,C3=<custom3>:pst,sst'
      )

      RTRV_INV_ALL = Command.new(
        'RTRV-INV',
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
        ].join(':')
      )

      RTRV_ALM_ALL = Command.new(
        'RTRV-ALM-ALL',
        [
          '<aid>,<aidtype>',
          [
            '<ntfcncde>',
            '<condtype>',
            '<srveff>',
            '<ocrdat>',
            '<ocrtim>',
            '<locn>',
            '<dirn>',
            '<tmper>'
          ].join(','),
          '<conddescr>,<aiddet>,<obsdbhvr>,<exptdbhvr>',
          '<dgntype>,<tblislt>'
        ].join(':')
      )

      RTRV_CRS_WCH = Command.new(
        'RTRV-CRS-WCH',
        '<from_aid>,<to_aid>::SERVICENAME=<service_name>'
      )

      RTRV_CRS_XCVR = Command.new(
        'RTRV-CRS-XCVR',
        '<src_aid>,<dst_aid>:<ctype>'
      )

      RTRV_CONN_EQPT = Command.new(
        'RTRV-CONN-EQPT',
        '<fromAid>,<toAid>:<type>'
      )

      RTRV_WDM = Command.new(
        'RTRV-WDM',
        [
          '<aid>',
          '',
          [
            '<ID=<id>',
            'C1=<custom1>',
            'C2=<custom2>',
            'C3=<custom3>',
            'FIBER=<fiber>',
            'SPANLEN=<spanlen>',
            'SPANLOSSSPECMAX=<spanlossspecmax>',
            'SPANLOSSRX-HT=<spanlossrx-ht>',
            'NUMCHNLS=<numchnls>',
            'AINSTMR=<ainstmr>',
            'ACTAINSTMR=<actainstmr>'
          ].join(','),
          '<pst>,<sst>'
        ].join(':')
      )

      RTRV_ROUTE_CONN = Command.new(
        'RTRV-ROUTE-CONN',
        [
          '',
          '<ipaddr>,<mask>,<nexthop>',
          [
            'COST=<cost>',
            'ADMINDIST=<admindist>',
            'TYPE=<type>',
            'PROT=<prot>',
            'AGE=<age>',
            'PREFSTAT=<prefstat>'
          ].join(',')
        ].join(':')
      )
    end # module BTI
  end # module Platforms
end # module TL1
