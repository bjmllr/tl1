# frozen_string_literal: true
require 'tl1/ast'
require 'tl1/command'
require 'tl1/input_format'
require 'tl1/output_format'
require 'tl1/session'
require 'tl1/version'

module TL1
  COMPLD = /COMPLD[\n\r]{1,2}.*;/m
end # module TL1
