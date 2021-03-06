#!/usr/bin/env lua

-- Usage: 

-- require "pepperfish"
function __FILE__() return debug.getinfo(2,'S').source end
function __LINE__() return debug.getinfo(2, 'l').currentline end

function logd(...)
   -- print(...)
end

local cache = require "cache"

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

local L1a = cache:new{
   name = "L1a",		-- L1 of 8KB
   word_size = 4,		-- word size in bytes
   blk_size = 64,		-- block size in bytes, 2^6
   n_blks = 64,			-- n_blks, 2^6
   assoc = 4,			-- assoc
   read_hit_delay = 1,		-- read_delay
   write_hit_delay = 2,		-- write_delay
   coherent_delay = 2,		-- coherent delay
   write_back = true,		-- write_back
   next_level = L2}		-- next_level

local L1b = cache:new{
   name = "L1b",		-- L1 of 8KB
   word_size = 4,		-- word size in bytes
   blk_size = 64,		-- block size in bytes, 2^6
   n_blks = 64,			-- n_blks, 2^6
   assoc = 4,			-- assoc
   read_hit_delay = 1,		-- read_delay
   write_hit_delay = 2,		-- write_delay
   coherent_delay = 2,		-- coherent delay
   write_back = true,		-- write_back
   next_level = L2}		-- next_level

local L1c = cache:new{
   name = "L1c",		-- L1 of 8KB
   word_size = 4,		-- word size in bytes
   blk_size = 64,		-- block size in bytes, 2^6
   n_blks = 64,			-- n_blks, 2^6
   assoc = 4,			-- assoc
   read_hit_delay = 1,		-- read_delay
   write_hit_delay = 2,		-- write_delay
   coherent_delay = 2,		-- coherent delay
   write_back = true,		-- write_back
   next_level = L2}		-- next_level

local L1d = cache:new{
   name = "L1d",		-- L1 of 8KB
   word_size = 4,		-- word size in bytes
   blk_size = 64,		-- block size in bytes, 2^6
   n_blks = 64,			-- n_blks, 2^6
   assoc = 4,			-- assoc
   read_hit_delay = 1,		-- read_delay
   write_hit_delay = 2,		-- write_delay
   coherent_delay = 2,		-- coherent delay
   write_back = true,		-- write_back
   next_level = L2}		-- next_level

L1a:set_peers({L1b, L1c, L1d})
L1b:set_peers({L1a, L1c, L1d})
L1c:set_peers({L1a, L1b, L1d})
L1d:set_peers({L1a, L1b, L1c})

local l1_cache_list = {L1a, L1b, L1c, L1d}

function issue(iss)
   local max_b_sz = 0
   for _, b in ipairs(iss) do
      if max_b_sz < #b then max_b_sz = #b end
   end
   
   for i = 1, max_b_sz do
      -- round robin with the cores, to simulate the parallel execution
      for _, b in ipairs(iss) do
	 line = b[i]
	 if line then	 	-- if not nil
	    local rw, addr, cid = string.match(line, "(%a) 0x(%x+) (%d)")
	    logd (line, rw, addr, cid)
	    local delay = 0
	    -- print(rw, addr, cid)
	    local L1 = l1_cache_list[tonumber(cid)]
	    if rw == 'W' then
	       logd("---W----")
	       delay = L1:write(tonumber(addr, 16))
	       logd("---W----")
	    elseif rw == 'R' then
	       logd("---R----")
	       delay = L1:read(tonumber(addr, 16))
	       logd("---R----")
	    end
	    logd('delay', delay)
	 end
      end
   end
   -- for _, b in ipairs(iss) do
   --    for i, line in ipairs(b) do
   --    end
   -- end
end

local BUFSIZE = 2^15		-- 32K
local f = io.input(arg[1])	-- open input file

while true do
   local lines, rest = f:read(BUFSIZE, "*line")
   if not lines then break end
   if rest then lines = lines .. rest .. "\n" end

   assert(loadstring(lines))()
end

-- for line in f:lines() do
--    if line:sub(1,2) ~= '--' then
--       local rw, addr, cid = string.match(line, "(%a) 0x(%x+) (%d)")
--       local delay = 0
--       -- print(rw, addr, cid)
--       local L1 = l1_cache_list[tonumber(cid)]
--       if rw == 'W' then
--       	 logd("---W----")
-- 	 delay = L1:write(tonumber(addr, 16))
-- 	 logd("---W----")
--       elseif rw == 'R' then
--       	 logd("---R----")
-- 	 delay = L1:read(tonumber(addr, 16))
-- 	 logd("---R----")
--       end
--       logd('delay', delay)
--    end
-- end


function summarize(cache_list)
   local read_hit_total, read_miss_total, write_hit_total, write_miss_total = 0,0,0,0
   for _, c in pairs(cache_list) do
      print(c.name)
      print("read hit/miss:", c.read_hit, c.read_miss)
      print("write hit/miss:", c.write_hit, c.write_miss)
      read_hit_total = read_hit_total + c.read_hit
      read_miss_total = read_miss_total + c.read_miss
      write_hit_total = write_hit_total + c.write_hit
      write_miss_total = write_miss_total + c.write_miss
   end
   print("Total read hit/miss:", read_hit_total, read_miss_total)
   print("Total write hit/miss:", write_hit_total, write_miss_total)
end

-- l1_cache_list[#l1_cache_list + 1] = l2
summarize(l1_cache_list)

