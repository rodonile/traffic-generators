------------------------- MERGE dump-pkts.lua and udp_load_timestamps.lua
local lm     = require "libmoon"
local device = require "device"
local memory = require "memory"
local stats  = require "stats"
local arp    = require "proto.arp"
local eth    = require "proto.ethernet"
local log    = require "log"
local pcap   = require "pcap"
local pf     = require "pf"
local mg     = require "moongen"
local ts     = require "timestamping"
local filter = require "filter"
local hist   = require "histogram"
local timer  = require "timer"

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

------------------------- PARSE ARGS
function configure(parser)
	parser:description("Generates UDP traffic and measure latencies. Edit the source to modify constants like IPs.")
	--device for transmission
    parser:argument("txDev", "Device to transmit from."):convert(tonumber)
	parser:argument("rxDev", "Device to receive from."):convert(tonumber)
    
    --transmission options
    parser:option("-r --rate", "Transmit rate in Mbit/s."):default(10000):convert(tonumber)
	parser:option("-n --flows", "Number of flows (randomized source IP)."):default(4):convert(tonumber)
	parser:option("-s --size", "Packet size."):default(60):convert(tonumber)
    parser:option("-z --time", "Moongen runtime"):default(60):convert(tonumber)

    --capturing options
	parser:option("-a --arp", "Respond to ARP queries on the given IP."):argname("ip")
	parser:option("-f --file", "Write result to a pcap file.")
	parser:option("-l --snap-len", "Truncate packets to this size."):convert(tonumber):target("snapLen")
	parser:option("-t --threads", "Number of threads."):convert(tonumber):default(1)
	parser:option("-o --output", "File to output statistics to")
	parser:argument("filter", "A BPF filter expression."):args("*"):combine()
	local args = parser:parse()
	if args.filter then
		local ok, err = pcall(pf.compile_filter, args.filter)
		if not ok then
			parser:error(err)
		end
	end
	return args
end

------------------------- MASTER
function master(args)
    --sending packets from 0 to 1 and capturing on 1
    txDev = device.config{port = args.txDev, rxQueues = 8, txQueues = 8}
	rxDev = device.config{port = args.rxDev, rxQueues = 8, txQueues = 8, rssQueues = 8}
	device.waitForLinks()
    
	if args.arp then
		arp.startArpTask{txQueue = rxDev:getTxQueue(3), ips = args.arp}
		arp.waitForStartup() -- race condition with arp.handlePacket() otherwise
	end
	--stats.startStatsTask{rxDevices = {rxDev}, file = args.output}
	
    
    --start capture threads of rx queues
    lm.startTask("dumper", rxDev:getRxQueue(0), args, 1)
    lm.startTask("dumper", rxDev:getRxQueue(1), args, 2)
    
    
    -- max 1kpps timestamping traffic timestamping
	-- rate will be somewhat off for high-latency links at low rates
    args_rate_adapted=args.rate - (args.size + 4) * 8 / 1000
    
    -----------------------------------
    --SINGLE CORE
    -----------------------------------
    --txDev:getTxQueue(0):setRate(args_rate_adapted)
    --mg.startTask("loadSlave", txDev:getTxQueue(0), rxDev, args.size, args.flows, args.time)
    -----------------------------------
    --MULTICORE (4 cores)
    -----------------------------------
    txDev:getTxQueue(0):setRate(args_rate_adapted/4)
    txDev:getTxQueue(1):setRate(args_rate_adapted/4)
    txDev:getTxQueue(4):setRate(args_rate_adapted/4)
    txDev:getTxQueue(5):setRate(args_rate_adapted/4)
    
	mg.startTask("loadSlave", txDev:getTxQueue(0), rxDev, args.size, args.flows, args.time)
    --add 3 additional threads to achieve link saturation with low payload (64bytes) packets
    mg.startTask("loadSlave", txDev:getTxQueue(1), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(4), rxDev, args.size, args.flows, args.time)
    mg.startTask("loadSlave", txDev:getTxQueue(5), rxDev, args.size, args.flows, args.time)
    
    stats.startStatsTask{txDev, rxDev}
    
    --Max one timestamper thread (otherwise time synchronization issues arise)
    mg.startTask("timerSlave", txDev:getTxQueue(6), rxDev:getRxQueue(6), args.size, args.flows, args.time)
    
	arp.startArpTask{
		-- run ARP on both ports  --queue was 2
		{ rxQueue = rxDev:getRxQueue(2), txQueue = rxDev:getTxQueue(2), ips = RX_IP },
		-- we need an IP address to do ARP requests on this interface
		{ rxQueue = txDev:getRxQueue(2), txQueue = txDev:getTxQueue(2), ips = ARP_IP }
	}
	mg.waitForTasks()
end	

------------------------- DUMPER FUNCTION
function dumper(queue, args, threadId)
	local handleArp = args.arp
	-- default: show everything
	local filter = args.filter and pf.compile_filter(args.filter) or function() return true end
	local snapLen = args.snapLen
	local writer
	local captureCtr, filterCtr
	if args.file then
		if args.threads > 1 then
			if args.file:match("%.pcap$") then
				args.file = args.file:gsub("%.pcap$", "")
			end
			args.file = args.file .. "-thread-" .. threadId .. ".pcap"
		else
			if not args.file:match("%.pcap$") then
				args.file = args.file .. ".pcap"
			end
		end
		writer = pcap:newWriter(args.file)
		captureCtr = stats:newPktRxCounter("Capture, thread #" .. threadId)
		filterCtr = stats:newPktRxCounter("Filter reject, thread #" .. threadId)
	end
	local bufs = memory.bufArray()
	while lm.running() do
		local rx = queue:tryRecv(bufs, 100)
		local batchTime = lm.getTime()
		for i = 1, rx do
			local buf = bufs[i]
			if filter(buf:getBytes(), buf:getSize()) then
				if writer then
					writer:writeBuf(batchTime, buf, snapLen)
					captureCtr:countPacket(buf)
				else
					buf:dump()
				end
			elseif filterCtr then
				filterCtr:countPacket(buf)
			end
			if handleArp and buf:getEthernetPacket().eth:getType() == eth.TYPE_ARP then
				-- inject arp packets to the ARP task
				-- this is done this way instead of using filters to also dump ARP packets here
				arp.handlePacket(buf)
			else
				-- do not free packets handlet by the ARP task, this is done by the arp task
				buf:free()
			end
		end
		if writer then
			captureCtr:update()
			filterCtr:update()
		end
	end
	if writer then
		captureCtr:finalize()
		filterCtr:finalize()
		log:info("Flushing buffers, this can take a while...")
		writer:close()
	end
end

------------------------- OTHER HELPER FUNCTIONS FOR TRANSMISSION AND TIMESTAMPING
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

function timerSlave(txQueue, rxQueue, size, flows, time)
	doArp()
	if size < 84 then
		log:warn("Packet size %d is smaller than minimum timestamp size 84. Timestamped packets will be larger than load packets.", size)
		size = 84
	end
	local timestamper = ts:newUdpTimestamper(txQueue, rxQueue)
	local hist = hist:new()
	mg.sleepMillis(1000) -- ensure that the load task is running
	local counter = 0
	local rateLimit = timer:new(0.001)
	local baseIP = parseIPAddress(SRC_IP_BASE)
    local runtime = timer:new(time)
	while mg.running() and runtime:running() do
		hist:update(timestamper:measureLatency(size, function(buf)
			fillUdpPacket(buf, size)
			local pkt = buf:getUdpPacket()
			pkt.ip4.src:set(baseIP + counter)
			counter = incAndWrap(counter, flows)
		end))
		rateLimit:wait()
		rateLimit:reset()
	end
	-- print the latency stats after all the other stuff
	mg.sleepMillis(300)
	hist:print()
	hist:save("histogram_udp_load.csv")
end