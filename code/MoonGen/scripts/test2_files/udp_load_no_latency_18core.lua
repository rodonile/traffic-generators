-- Made for 100Gbps server testing
-- One sided traffic p1p1-->p1p2 with 8 cores that send packets
local mg     = require "moongen"
local memory = require "memory"
local device = require "device"
local filter = require "filter"
local hist   = require "histogram"
local stats  = require "stats"
local timer  = require "timer"
local arp    = require "proto.arp"
local log    = require "log"

-- set addresses here
local DST_MAC		= nil -- resolved via ARP on GW_IP or DST_IP, can be overriden with a string here
local SRC_IP_BASE	= "10.0.0.10" -- actual address will be SRC_IP_BASE + random(0, flows)
local DST_IP		= "10.1.0.10"
local SRC_PORT		= 1234
local DST_PORT		= 319

-- answer ARP requests for this IP on the rx port
-- change this if benchmarking something like a NAT device
local RX_IP		= DST_IP
-- used to resolve DST_MAC
local GW_IP		= DST_IP
-- used as source IP to resolve GW_IP to DST_MAC
local ARP_IP	= SRC_IP_BASE

function configure(parser)
	parser:description("Generates UDP traffic and measure latencies. Edit the source to modify constants like IPs.")
	parser:argument("txDev", "Device to transmit from."):convert(tonumber)
	parser:argument("rxDev", "Device to receive from."):convert(tonumber)
	parser:option("-r --rate", "Transmit rate in Mbit/s."):default(10000):convert(tonumber)
	parser:option("-f --flows", "Number of flows (randomized source IP)."):default(4):convert(tonumber)
	parser:option("-s --size", "Packet size."):default(60):convert(tonumber)
    parser:option("-t --time", "Moongen runtime"):default(60):convert(tonumber)
end

function master(args)
	txDev = device.config{port = args.txDev, rxQueues = 24, txQueues = 24}
	rxDev = device.config{port = args.rxDev, rxQueues = 24, txQueues = 24}
	device.waitForLinks()
	-- max 1kpps timestamping traffic timestamping
	-- rate will be somewhat off for high-latency links at low rates
    args_rate_adapted = args.rate - (args.size + 4) * 8 / 1000
    
    txDev:getTxQueue(0):setRate(args_rate_adapted/18)
    txDev:getTxQueue(1):setRate(args_rate_adapted/18)
    txDev:getTxQueue(4):setRate(args_rate_adapted/18)
    txDev:getTxQueue(5):setRate(args_rate_adapted/18)
    txDev:getTxQueue(6):setRate(args_rate_adapted/18)
    txDev:getTxQueue(7):setRate(args_rate_adapted/18)
    txDev:getTxQueue(8):setRate(args_rate_adapted/18)
    txDev:getTxQueue(9):setRate(args_rate_adapted/18)
    txDev:getTxQueue(10):setRate(args_rate_adapted/18)
    txDev:getTxQueue(11):setRate(args_rate_adapted/18)
    txDev:getTxQueue(12):setRate(args_rate_adapted/18)
    txDev:getTxQueue(13):setRate(args_rate_adapted/18)
    txDev:getTxQueue(14):setRate(args_rate_adapted/18)
    txDev:getTxQueue(15):setRate(args_rate_adapted/18)
    txDev:getTxQueue(16):setRate(args_rate_adapted/18)
    txDev:getTxQueue(17):setRate(args_rate_adapted/18)
    txDev:getTxQueue(18):setRate(args_rate_adapted/18)
    txDev:getTxQueue(19):setRate(args_rate_adapted/18)
    
	mg.startTask("loadSlave", txDev:getTxQueue(0), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(1), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(4), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(5), rxDev, args.size, args.flows, args.time)
	mg.startTask("loadSlave", txDev:getTxQueue(6), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(7), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(8), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(9), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(10), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(11), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(12), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(13), rxDev, args.size, args.flows, args.time)
	mg.startTask("loadSlave", txDev:getTxQueue(14), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(15), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(16), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(17), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(18), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(19), rxDev, args.size, args.flows, args.time)
    
    stats.startStatsTask{txDev, rxDev}
    
	arp.startArpTask{
		-- run ARP on both ports
		{ rxQueue = rxDev:getRxQueue(2), txQueue = rxDev:getTxQueue(2), ips = RX_IP },
		-- we need an IP address to do ARP requests on this interface
		{ rxQueue = txDev:getRxQueue(2), txQueue = txDev:getTxQueue(2), ips = ARP_IP }
	}
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

local function doArp()
	if not DST_MAC then
		log:info("Performing ARP lookup on %s", GW_IP)
		DST_MAC = arp.blockingLookup(GW_IP, 5)
		if not DST_MAC then
			log:info("ARP lookup failed, using default destination mac address")
			return
		end
	end
	log:info("Destination mac: %s", DST_MAC)
end

function loadSlave(queue, rxDev, size, flows, time)
	doArp()
	local mempool = memory.createMemPool(function(buf)
		fillUdpPacket(buf, size)
	end)
	local bufs = mempool:bufArray()
	local counter = 0
    --I enabled global stats outside such that it's readable
	--local txCtr = stats:newDevTxCounter(queue, "plain")
	--local rxCtr = stats:newDevRxCounter(rxDev, "plain")
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
		--txCtr:update()
		--rxCtr:update()
	end
        
	--txCtr:finalize()
	--rxCtr:finalize()
end
