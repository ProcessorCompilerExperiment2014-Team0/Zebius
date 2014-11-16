#!/usr/bin/ruby2.0

$zasm = "/home/zeptometer/Share/Zebius/asm/zasm"

if (ARGV.length != 1 && ARGV.length != 2)
  puts "usage: zasml asm (input)"
  exit
end

code = ARGV[0]
data = if (ARGV.length == 2)
         ARGV[1]
       else
         nil
       end
bin = code[0...-2]

p "#$zasm #{code} -s 256"
`#$zasm #{code} -s 256`
size = File.size(bin);

File.open("tmp", "wb") {|f| f.write([size].pack("N"))}
`cat tmp #{bin} #{data || ""} > #{bin}.input`
`rm tmp`
