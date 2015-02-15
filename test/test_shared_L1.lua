#!/usr/bin/env lua

-- Usage: 

-- require "pepperfish"
function __FILE__() return debug.getinfo(2,'S').source end
function __LINE__() return debug.getinfo(2, 'l').currentline end

function logd(...)
   -- print(...)
end

local cache = require "../cache"

local L2 = cache:new{
   name = "L2",			-- L2 of 8KB
   word_size = 4,		-- word size in bytes
   blk_size = 64,		-- block size in bytes, 2^6
   n_blks = 1024,		-- n_blks, 2^10
   assoc = 4,			-- assoc
   read_hit_delay = 4,		-- read delay
   write_hit_delay = 8,		-- write delay
   coherent_delay = 8,		-- coherent delay
   write_back = true,		-- write back
   next_level = nil}		-- next level

local L1 = cache:new{
   name = "L1",			-- L1 of 8KB
   word_size = 4,		-- word size in bytes
   blk_size = 64,		-- block size in bytes, 2^6
   n_blks = 256,		-- n_blks, 2^8
   assoc = 4,			-- assoc
   read_hit_delay = 1,		-- read_delay
   write_hit_delay = 2,		-- write_delay
   coherent_delay = 2,		-- coherent delay
   write_back = true,		-- write_back
   next_level = L2}		-- next_level

local BUFSIZE = 2^8		-- 32K
local f = io.input(arg[1])	-- open input file

for line in f:lines() do
   if line:sub(1,2) ~= '--' then
      local rw, addr, cid = string.match(line, "(%a) 0x(%x+) (%d)")
      local delay = 0

      if rw == 'W' then
      	 logd("<<<<W<<<<")
	 delay = L1:write(tonumber(addr, 16))
	 logd(">>>>W>>>>")
      elseif rw == 'R' then
      	 logd("<<<<R<<<<")
	 delay = L1:read(tonumber(addr, 16))
	 logd(">>>>R>>>>")
      end
      logd('delay', delay)
   end
end

function summarize(cache_list) 
   for _, c in pairs(cache_list) do
      print(c.name)
      print("read hit/miss:", c.read_hit, c.read_miss)
      print("write hit/miss:", c.write_hit, c.write_miss)
   end
end

summarize{L1, L2}

