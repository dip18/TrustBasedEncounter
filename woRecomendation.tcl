puts "\nEnter the main node"
set query [gets stdin]
puts "\nEnter the node you want to query"
set stat  [gets stdin]

set fid [open "coord.txt" r]
set content [read $fid]
close $fid
set a 0
# Split by newlines
set records [split $content "\n"]
foreach rec $records {
   # Split by comma
   set fields [split $rec ","]
   lassign $fields \
         x y 
	set xx($a) $x
	set yy($a) $y
	set a [expr $a+1]
}

#=====================================
# Define options
#=====================================
set val(chan) Channel/WirelessChannel 			;# channel type
set val(prop) Propagation/TwoRayGround 			;# radio-propagation model
set val(mac) Mac/802_11 				;# MAC type
set val(ifq) Queue/DropTail/PriQueue 			;# interface queue type
set val(ll) LL 						;# link layer type
set val(ant) Antenna/OmniAntenna 			;# antenna model
Antenna/OmniAntenna set X_ 0
Antenna/OmniAntenna set Y_ 0
Antenna/OmniAntenna set Z_ 1.5
Antenna/OmniAntenna set Gt_ 1.0
Antenna/OmniAntenna set Gr_ 1.0
set val(ifqlen) 10 					;# max packet in ifq
set val(nn) 70 						;# number of mobilenodes
set val(rp) AODV 					;# routing protocol
set val(x) 1000 					;# X dimension of topography
set val(y) 1000 					;# Y dimension of topography
set val(stop) 250 					;# time of simulation end
set val(netif)          Phy/WirelessPhy            	;# network interface type
set val(batterymodel)   Battery/Simple             	;# battery model
set val(batterymonitor) "on"
set val(initialenergy)  36                        	;# Initial battery capacity 
set val(radiomodel)     Radio/Simple               	;# generic radio hardware
set val(receivepower)   .5                        	;# Receiving Power
set val(transmitpower)  .5                         	;# Transmitting Power
set val(idlepower)      .05                        	;# Idle Power


LL set mindelay_                50us
LL set delay_                   25us
LL set bandwidth_               0       		;# not used

Queue/DropTail/PriQueue set Prefer_Routing_Protocols    1
$val(netif) set CSThresh_ 2.28289e-11  			;#sensing range of 500m
$val(netif) set RXThresh_ 2.28289e-11  			;#communication range of 500m
set ns [new Simulator]
set tracefd [open woRecomendation.tr w]
set namtrace [open woRecomendation.nam w]

set chan_1_ [new $val(chan)]
$ns trace-all $tracefd
$ns namtrace-all-wireless $namtrace $val(x) $val(y)

# Set up topography object
set topo [new Topography]

$topo load_flatgrid $val(x) $val(y)

create-god $val(nn)



# Configure the nodes
$ns node-config -adhocRouting $val(rp) \
-llType $val(ll) \
-macType $val(mac) \
-ifqType $val(ifq) \
-ifqLen $val(ifqlen) \
-antType $val(ant) \
-propType $val(prop) \
-phyType $val(netif) \
-channelType $val(chan) \
-topoInstance $topo \
-agentTrace ON \
-routerTrace ON \
-macTrace OFF \
-movementTrace ON

for {set i 0} {$i < $val(nn) } { incr i } {
set node($i) [$ns node]

}


for {set i 0} {$i < $val(nn) } { incr i } {
$node($i) set X_ $xx($i)
$node($i) set Y_ $yy($i)
$node($i) set Z_ 0.0

set nodeNum($i) $i
}

set fid [open "dest.txt" r]
set content [read $fid]
close $fid
set a 0
# Split by newlines
set records [split $content "\n"]
foreach rec $records {
   # Split by comma
   set fields [split $rec ","]
   lassign $fields \
         x y z
	set destix($a) $x
	set destiy($a) $y
	set speed1($a) $z
	set a [expr $a+1]
	
}

set fid [open "fn.txt" r]
set content [read $fid]
close $fid
set a 0
# Split by newlines
set records [split $content "\n"]
foreach rec $records {
   # Split by comma
   set fields [split $rec ","]
   lassign $fields \
         x y z m
	set destix1($a) $x
	set destiy1($a) $y
	set fastnode1($a) $z
	set newspeed($a) $m
	set a [expr $a+1]
	
}

set fid [open "pt.txt" r]
set content [read $fid]
close $fid
set b 0
# Split by newlines
set records [split $content "\n"]
foreach rec $records {
   # Split by comma
   set fields [split $rec ","]
   lassign $fields \
         p sd
	set pause $p
	set pbcd $sd
	set b [expr $b+1]
}

set fid [open "mal.txt" r]
set content [read $fid]
close $fid
set b 0
# Split by newlines
set records [split $content "\n"]
foreach rec $records {
   # Split by comma
   set fields [split $rec ","]
   lassign $fields \
         malici no
	set malicious($b) $malici
	set b [expr $b+1]
}
set a 0
set malsz [array size malicious]
for {set mm 0} {$mm<[expr $malsz-1]} {incr mm} {
	set a [expr $a+.01]


$ns at $a "[$node($malicious($mm)) set ragent_] malicious"
$ns at $a "$node($malicious($mm)) add-mark N2 red circle"

}

for {set i 0} {$i < $val(nn) } { incr i } {
set speed $speed1($i)
set newx $destix($i)
set newy $destiy($i)
$ns at $pause "$node($i) setdest $newx $newy $speed"
}

for {set i 0} {$i < 5} { incr i } {
set fast  $fastnode1($i)
set speed_fast $newspeed($i)  

set newx1 $destix1($i)
set newy2 $destiy1($i) 
$ns at $pause "$node($fast) setdest $newx1 $newy2 $speed_fast"
$ns at $pause "$node($fast) add-mark N2 green circle"
}

#Setup a TCP connection
set tstart1 .1
set tstop1 1
set tstart2 150
set tstop2 200.5
set ann 10.1



set tcp [new Agent/TCP/Newreno]
$ns attach-agent $node($query) $tcp
set sink [new Agent/TCPSink/DelAck]
$ns attach-agent $node($stat) $sink
$ns connect $tcp $sink
$tcp set fid_ 1
$tcp set window_ 8000
$tcp set packetSize_ 552
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP

#Setup a UDP connection
set udp [new Agent/UDP]
$ns attach-agent $node($query) $udp
set null [new Agent/Null]
$ns attach-agent $node($stat) $null
$ns connect $udp $null
$udp set fid_ 2

#Setup a CBR over UDP connection
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ 0.01mb
$cbr set random_ false

$ns at $tstart1 "$cbr start"
$ns at $tstop1 "$ftp start"
$ns at $tstart2 "$ftp stop"
$ns at $tstop2 "$cbr stop"

$ns at $ann "$ns trace-annotate \"Green nodes are fast mobile nodes\""
set tstart1 [expr $tstart1+10]
set tstop1 [expr $tstop1+10]
set tstart2 [expr $tstart2+10]
set tstop2 [expr $tstop2+10]
set ann [expr $ann+10]



set timer 0
# Define node initial position in nam
for {set i 0} {$i < $val(nn)} { incr i } {
# 40 defines the node size for nam
$ns initial_node_pos $node($i) 40
}

# Telling nodes when the simulation ends
for {set i 0} {$i < $val(nn) } { incr i } {
$ns at $val(stop) "$node($i) reset";
}

# ending nam and the simulation
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "stop"
$ns at 250.01 "puts \"end simulation\" ; $ns halt"
proc stop {} {
global ns tracefd namtrace
$ns flush-trace
close $tracefd
close $namtrace
exec nam woRecomendation.nam &
}

#Print CBR packet size and interval
puts "CBR packet size = [$cbr set packet_size_]"
puts "CBR interval = [$cbr set interval_]"
$ns run 

