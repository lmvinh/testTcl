

proc getMinList {listcell} {
	set cur 10
	foreach i $listcell {
		if {$cur > [llength $i]} {set cur [llength i]}
	}
	return $cur
}

proc checkIsEquivalentBlock {block1 block2 level} {
	set isValid 1
	for {set i 0} {$i < [expr $level -1]} {incr i} {
		if {[lindex $block1 $i] != [lindex $block2 $i]} {set isValid 0;break}
	}
	return $isValid;
}

set min 10;set max 0

set list_block_cell [dbget [dbget top.insts.cell.baseClass block -p2 -u].name]
set list_block_cell_split []
foreach i $list_block_cell {lappend list_block_cell_split [split $i "/"]}
foreach i $list_block_cell_split {
	if {$min > [llength $i]} {set min [llength $i]}
}
foreach i $list_block_cell_split {
        if {$max < [llength $i]} {set max [llength $i]}
}
puts $min; puts $max; set total_list []
for {set i $min} {$i <= $max} {incr i} {
	set local_list []
	foreach j $list_block_cell_split {
		if {$i == [llength $j]} {lappend local_list $j}
	}
	lappend total_list $local_list
}
puts "##---INFO---There is a total of $max hierarchy in module cell! Which level should you gather for it ^_^!"
gets stdin level

set index_total 0
set sort_list []
set local_list []
foreach i $total_list {
	for {set j 0} {$j < [llength  $i ]} {incr j} {
		set local_list []
		#puts [llength [lindex $i $index_total]]
		lappend local_list [lindex $i $j]
		for {set k [expr $j + 1]} {$k < [llength $i]} {incr k } {
			puts [lindex $local_list 0]
			if {[checkIsEquivalentBlock [lindex $local_list 0] [lindex $i $k] $level] == 1} {
				lappend local_list [lindex $i $k]			
			} else {
				lappend	sort_list $local_list
				puts $sort_list
				set j [expr $k-1]; set local_list []
				break							
			}
		}
	}
}
set final_list []
foreach i $sort_list {
	set local_list []
	foreach j $i {
		set block_compl [string map {" " /} $j]
		lappend local_list $block_compl	
	}
	lappend final_list $local_list	
}
#foreach i $final_list {puts "\n";foreach j $i {puts $j}}
set index_color 1
foreach i $final_list {
	if {$index_color > 63} {set index_color 1}
	foreach j $i {
		selectInst $j
		highlight -index $index_color
		deselectAll		
	}
	incr index_color
}
