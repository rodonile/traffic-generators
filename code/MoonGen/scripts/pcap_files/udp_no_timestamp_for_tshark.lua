--udp packets sent with 4 threads without timestamps on packets

local mg     = require "moongen"
local memory = require "memory"
local device = require "device"
local ts     = require "timestamping"
local filter = require "filter"
local hist   = require "histogram"
local stats  = require "stats"
local timer  = require "timer"
local arp    = require "proto.arp"
local log    = require "log"

-- set addresses here
local DST_MAC		= "f8:f2:1e:09:62:d1" -- removed ARP resolution
local SRC_IP_BASE	= "10.0.0.10" -- actual address will be SRC_IP_BASE + random(0, flows)
local DST_IP		= "10.1.0.10"
local SRC_PORT		= 1234
local DST_PORT		= 319


function configure(parser)
	parser:description("Generates UDP traffic and measure latencies. Edit the source to modify constants like IPs.")
	parser:argument("txDev", "Device to transmit from."):convert(tonumber)
	parser:option("-r --rate", "Transmit rate in Mbit/s."):default(10000):convert(tonumber)
	parser:option("-f --flows", "Number of flows (randomized source IP)."):default(4):convert(tonumber)
	parser:option("-s --size", "Packet size."):default(60):convert(tonumber)
    parser:option("-t --time", "Moongen runtime"):default(60):convert(tonumber)
end

function master(args)
	txDev = device.config{port = args.txDev, rxQueues = 8, txQueues = 8}
	device.waitForLinks()
	-- max 1kpps timestamping traffic timestamping
	-- rate will be somewhat off for high-latency links at low rates
    --args_rate_adapted=args.rate - (args.size + 4) * 8 / 1000
    args_rate_adapted = args.rate
    txDev:getTxQueue(0):setRate(args_rate_adapted/4)
    txDev:getTxQueue(1):setRate(args_rate_adapted/4)
    txDev:getTxQueue(4):setRate(args_rate_adapted/4)
    txDev:getTxQueue(5):setRate(args_rate_adapted/4)
    
	mg.startTask("loadSlave", txDev:getTxQueue(0), args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(1), args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(4), args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(5), args.size, args.flows, args.time)
    
    
    -- TESTING IF PERFORMANCE OF ONLY SENDING WITH ONE THREAD IS HIGHER THAN WITH test2.sh at 1core (answer no!)
    -- to test this disable threads & queues above and enable following 2 lines
    --txDev:getTxQueue(0):setRate(args_rate_adapted)
	--mg.startTask("loadSlave", txDev:getTxQueue(0), args.size, args.flows, args.time)
    
    stats.startStatsTask{txDev}
    
	mg.waitForTasks()
end

local function fillUdpPacket(buf, len)
	buf:getUdpPacket():fill{
		ethSrc = queue,
		ethDst = DST_MAC,
		ip4Src = SRC_IP,
		ip4Dst = DST_IP,
		udpSrc = SRC_PORT,
		udpDst = DST_PORT,
		pktLength = len
	}
end


function loadSlave(queue, size, flows, time)
	local mempool = memory.createMemPool(function(buf)
		fillUdpPacket(buf, size)
	end)
	local bufs = mempool:bufArray()
	local counter = 0
	
	local baseIP = parseIPAddress(SRC_IP_BASE)
	
    --Set time limit for execution
    local runtime = timer:new(time)
    
    while mg.running() and runtime:running() do
		bufs:alloc(size)
		for i, buf in ipairs(bufs) do
			local pkt = buf:getUdpPacket()
			pkt.ip4.src:set(baseIP + counter)
			counter = incAndWrap(counter, flows)
		end
		-- UDP checksums are optional, so using just IPv4 checksums would be sufficient here
		bufs:offloadUdpChecksums()
		queue:send(bufs)
	end
end
