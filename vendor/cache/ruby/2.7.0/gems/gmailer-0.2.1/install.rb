require 'rbconfig'
require 'ftools'
include Config

sitelibdir = CONFIG["sitelibdir"]
file = "gmailer.rb"

File.copy(file, sitelibdir, true)
