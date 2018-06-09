set val(nn) 70 				;# number of mobilenodes
# Checking the no of nodes in a set
set fid [open "dist.txt" r]
set content [read $fid]
close $fid
set a 0
set records [split $content "\n"]
foreach rec $records {
   # Split by comma
   set fields [split $rec ","]
   lassign $fields \
         sc dest dis t
	set s($a) $sc
	set d($a) $dest
	set dist($a) $dis
	set tim($a) $t
	set a [expr $a+1]
	
}



set fid [open "pt.txt" r]
set content [read $fid]
close $fid
set b 0
set records [split $content "\n"]
foreach rec $records {
   # Split by comma
   set fields [split $rec ","]
   lassign $fields \
         p sd
	set pp($b) $p
	set pbcd($b) $sd
	set b [expr $b+1]
}


set p 0
puts "...........$a"
puts "-----------$pp(0)"
set a [expr $a-1]
set nbr [open wAER w]
close $nbr
for {set x 0} {$x<$val(nn)} {incr x} {
set nbr [open wAER a]
set wei_total 0
set avg 0
set ncount 0
set co1 0
set arr 0
set co 0
set p [expr $p+1]
set pcopy $pp(0)
set flag 0
	while {$co<4} {
	
		while {$co1<$a} {
			
			if {$s($co1)==$x && $tim($co1)==$pcopy} {
				set m [array size newnei]
				for {set k 0} {$k<$m} {incr k} {
					if {$d($co1)==$newnei($k)} {
						set flag 1
						break
					}
				}
				if {$flag==0} {	
					set newnei($arr) $d($co1)
					set arr [expr $arr+1]
					set ncount [expr $ncount+1]
					puts "new node found at $pcopy!!!!"
				}
			}
			set flag 0
			set co1 [expr $co1+1]
		}
		set flag 0
		set co [expr $co+1]
		set pcopy [expr $pcopy+50.0000000000000000]
		set co1 0
		puts "time=$co , array size=$m"
		puts "time lapse $co, neighbour ($x) cardinality=$ncount"
		set avg [expr $avg+$ncount]
		if {$ncount>=7} {
			set w .1
			set weighted_er [expr $w*$ncount]
			} elseif {$ncount >=5 && $ncount<7} {
				set w .5
				set weighted_er [expr $w*$ncount]
			} else {
				set w 1
				set weighted_er [expr $w*$ncount]
			}
		set ncount 0
		puts "time lapse $co, neighbour ($x)weighted encounter rate=$weighted_er"
	}
set wei_total [expr $wei_total+$weighted_er]
puts "weighted aer=$wei_total"
puts $nbr "$x,$wei_total"
set total [expr $avg/4]
puts "\npress enter"
set data [gets stdin]
for {set k 0} {$k<$m} {incr k} {
	set newnei($k) -1
}
close $nbr	
}
		

