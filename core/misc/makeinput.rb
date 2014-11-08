#!/usr/bin/ruby2.0

code = ARGV[0]
data = if (ARGV.length == 2)
         ARGV[1]
       else
         nil
       end

size = File.size(code);

File.open("tmp", "wb") {|f| f.write([size].pack("N"))}
`cat tmp #{code} #{data || ""} > input.bin`
`rm tmp`