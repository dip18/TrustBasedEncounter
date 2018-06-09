#=====================================
# Define options
#=====================================
set val(chan) Channel/WirelessChannel              ;# channel type
set val(prop) Propagation/TwoRayGround             ;# radio-propagation model
set val(mac) Mac/802_11                            ;# MAC type
set val(ifq) Queue/DropTail/PriQueue               ;# interface queue type
set val(ll) LL                                     ;# link layer type
set val(ant) Antenna/OmniAntenna                   ;# antenna model
Antenna/OmniAntenna set X_ 0
Antenna/OmniAntenna set Y_ 0
Antenna/OmniAntenna set Z_ 1.5
Antenna/OmniAntenna set Gt_ 1.0
Antenna/OmniAntenna set Gr_ 1.0
set val(ifqlen) 10                                 ;# max packet in ifq
set val(nn) 70                                     ;# number of mobilenodes
set val(rp) AODV                                   ;# routing protocol
set val(x) 1000                                    ;# X dimension of topography
set val(y) 1000                                    ;# Y dimension of topography
set val(stop) 250                                  ;# time of simulation end
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(batterymodel)   Battery/Simple             ;# battery model
set val(batterymonitor) "on"
set val(initialenergy)  36                         ;# Initial battery capacity 
set val(radiomodel)     Radio/Simple               ;# generic radio hardware
set val(receivepower)   .5                         ;# Receiving Power
set val(transmitpower)  .5                         ;# Transmitting Power
set val(idlepower)      .05                        ;# Idle Power


LL set mindelay_                50us
LL set delay_                   25us
LL set bandwidth_               0                  ;# not used

Queue/DropTail/PriQueue set Prefer_Routing_Protocols    1
$val(netif) set CSThresh_ 2.28289e-11  ;#sensing range of 500m
$val(netif) set RXThresh_ 2.28289e-11  ;#communication range of 500m
set ns [new Simulator]
set tracefd [open trust.tr w]
set namtrace [open trust.nam w]

# Procedure
set nbr [open dist.txt w]
close $nbr
set nbr [open fn.txt w]
close $nbr
set nbr [open tcpp.txt w]
close $nbr
set nbr [open coord.txt w]
close $nbr
set nbr [open mal.txt w]
close $nbr
global ncount
proc distance { n1 n2 nd1 nd2 times} {
set nbr [open dist.txt a]
	global c n bnd src dst j0 j1
	set x1 [expr int([$n1 set X_])]
	set y1 [expr int([$n1 set Y_])]
	set x2 [expr int([$n2 set X_])]
	set y2 [expr int([$n2 set Y_])]
	set d [expr int(sqrt(pow(($x2-$x1),2)+pow(($y2-$y1),2)))]
	if {$d<=500} {
		if {$nd1!=$nd2} {
			puts $nbr "$nd1,$nd2,$d,$times"
		}	
	} else {
	
	}
	close $nbr
}

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
set loc1 0
set loc2 0
set nbr [open coord.txt a]

for {set i 0} {$i < $val(nn) } { incr i } {

set xx [expr rand()*1000]
set yy [expr rand()*1000]
$node($i) set X_ $xx
$node($i) set Y_ $yy
$node($i) set Z_ 0.0
puts $nbr "$xx,$yy"
set nodeNum($i) $i
}
close $nbr
set nbr [open dest.txt w]
close $nbr
set nbr [open dest.txt a]
set pause [expr rand()*15]
for {set i 0} {$i < $val(nn) } { incr i } {
set speed [expr rand()]
set newx [expr rand()*1000]
set newy [expr rand()*1000]
puts $nbr "$newx,$newy,$speed"
$ns at $pause "$node($i) setdest $newx $newy $speed"
}
close $nbr
set max_speed 0
set nbr [open fn.txt a]
for {set i 0} {$i < 5} { incr i } {
set fast [expr round(rand()*[expr $val(nn)-1])]  
set speed_fast [expr round(rand()*5)]   
if {$speed_fast>$max_speed} {
set max_speed $speed_fast
}
set newx1 [expr rand()*1000]
set newy2 [expr rand()*1000]
puts $nbr "$newx1,$newy2,$fast,$speed_fast"
$ns at $pause "$node($fast) setdest $newx1 $newy2 $speed_fast"
$ns at $pause "$node($fast) add-mark N2 green circle"
}
close $nbr
set z 0
set pcopy $pause

# Calculating neighbours of mobile nodes 
while {$z<4} {
for {set i 0} {$i <$val(nn)} {incr i} {
      for {set j 0} {$j <$val(nn)} {incr j} {

        $ns at $pause "distance $node($i) $node($j) $i $j $pause" 
      }

    }

set z [expr $z+1]
set pause [expr $pause+50.0000000000000000]
}
set a 0
set nbr [open mal.txt a]

for {set i 0} {$i < 15} { incr i } {
set a [expr $a+.01]
set mal [expr round(rand()*[expr $val(nn)-1])]
puts $nbr "$mal" 
$ns at $a "[$node($mal) set ragent_] malicious"
$ns at $a "$node($mal) add-mark N2 red circle"
}
close $nbr
puts " \n THE MAX SPEED IS $max_speed"

#Setup a TCP connection
set p1 [expr round(rand()*[expr $val(nn)-1])]
set p2 [expr round(rand()*[expr $val(nn)-1])]
puts "$p1----$p2\n"

set tcp [new Agent/TCP/Newreno]
$ns attach-agent $node($p1) $tcp
set sink [new Agent/TCPSink/DelAck]
$ns attach-agent $node($p2) $sink
$ns connect $tcp $sink
$tcp set fid_ 1
$tcp set window_ 8000
$tcp set packetSize_ 552
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP



set nbr [open pt.txt w]
close $nbr
set nbr [open pt.txt a]
puts $nbr "$pcopy,0"
close $nbr

#Setup a UDP connection
set udp [new Agent/UDP]
$ns attach-agent $node($p1) $udp
set null [new Agent/Null]
$ns attach-agent $node($p2) $null
$ns connect $udp $null
$udp set fid_ 2

#Setup a CBR over UDP connection
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ 0.01mb
$cbr set random_ false

$ns at 0.1 "$cbr start"
$ns at 1.0 "$ftp start"
$ns at 250.01 "$ftp stop"
$ns at 250.01 "$cbr stop"


$ns at 10.1 "$ns trace-annotate \"Green nodes are fast mobile nodes\""

$ns at 10.1 "$ns trace-annotate \"Red nodes are malicious nodes\""
set a 10
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
exec nam trust.nam &
}

#Print CBR packet size and interval
puts "CBR packet size = [$cbr set packet_size_]"
puts "CBR interval = [$cbr set interval_]"
$ns run 

