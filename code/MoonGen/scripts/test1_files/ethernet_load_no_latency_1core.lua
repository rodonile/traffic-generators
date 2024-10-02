local mg     = require "moongen"
local memory = require "memory"
local device = require "device"
local stats  = require "stats"
local hist   = require "histogram"

local ETH_DST	= "11:12:13:14:15:16"

local function getRstFile(...)
	local args = { ... }
	for i, v in ipairs(args) do
		result, count = string.gsub(v, "%-%-result%=", "")
		if (count == 1) then
			return i, result
		end
	end
	return nil, nil
end

function configure(parser)
	parser:description("Generates bidirectional CBR traffic with hardware rate control and measure latencies.")
	parser:argument("dev1", "Device to transmit/receive from."):convert(tonumber)
	parser:argument("dev2", "Device to transmit/receive from."):convert(tonumber)
	parser:option("-r --rate", "Transmit rate in Mbit/s."):default(10000):convert(tonumber)
    parser:option("-s --pktsize", "Size of packet"):default(60):convert(tonumber)
	parser:option("-f --file", "Filename of the latency histogram."):default("histogram_first.csv")
end


function master(args)
	local dev1 = device.config({port = args.dev1, txQueues = 3})
	local dev2 = device.config({port = args.dev2, rxQueues = 3})
	device.waitForLinks()
	
    -- Initialize 2 queues
    dev1:getTxQueue(0):setRate(args.rate)
    
    -- Start 2 threads (one per queue)
    mg.startTask("loadSlave", dev1:getTxQueue(0), args.pktsize)
    stats.startStatsTask{dev1, dev2}
	mg.waitForTasks()
end

function loadSlave(queue, pktsize)
	local mem = memory.createMemPool(function(buf)
		buf:getEthernetPacket():fill{
			ethSrc = txDev,
			ethDst = ETH_DST,
			ethType = 0x1234
		}
	end)
	local bufs = mem:bufArray()
	while mg.running() do
		bufs:alloc(pktsize)
        queue:send(bufs)
	end
end