clearDrc
file delete -force "[pwd]/Snapshot/"
set restore_db_file_check 0
set restore_db_stop_at_design_in_memory 0
global vars env
set vars(script_root) /home/t_FX61AA021A_PR/FX61AA021A/PartitionPR/TRIAL_ENV_KHOI/SAMPLE_CENTRAL_ROOT_DIR_LATEST/current 
Puts "########################################################################################"
Puts "### Setup"
Puts "########################################################################################"
#source $vars(script_root)/project.tcl -e -v ; #[TODO user can not change, if change, please advise BC/PM]
source /home/t_FX61AA021A_PR/FX61AA021A/PartitionPR/balboa_snic_top_Vinhne/R1P0b_newFlow/FDI/kw_balboa_top_grovf_rdma_ip_w_ram_0/sample_AC_release_FP_SDC01202026_v1/pr/script/user_setting.tcl -e -v
set fw_csv [open ./test.csv w]
set stt 0
set fw [open test.rpt w]
set inst_name [dbget [dbget top.insts.cell.baseClass block -p2].name]
set inst_macro [dbget [dbget top.insts.cell.baseClass core -p2].name]
set unique_inst [dbget [dbget top.insts.cell.baseClass core -p1 -u].name]
set inst_name_cell [dbget [dbget top.insts.cell.baseClass block -p2 -u].name]
puts  "################# Count number of macros in the design, and list unique their cellname"
puts  "Number of block  : [llength $inst_name] ############"
puts  "Number of std  : [llength $inst_macro] ############"
puts  "Cell name unique : $unique_inst"

proc summaryDrc {} {
	set total []
	set uniqueDrc [dbget top.markers.subType -u]
	foreach drc $uniqueDrc	 {
		set local []
		lappend local $drc
		set num 0
		set drcTotal [dbget top.markers.subType] 
		foreach i $drcTotal {
			if {$drc == $i} {incr num}
		}
		lappend local $num
		lappend total $local    
	}
	return $total
}
proc check_dir {dirPath} {
	if {![file isdirectory $dirPath]} {
  	  puts "Directory '$dirPath' does not exist. Creating it..."
  	  file mkdir $dirPath
     	
    } else {
    	puts "Directory '$dirPath' already exists."
	}
}
proc export_gif_quyen {} {
### Show only NarrowChannel markers
	set type_Marker []
	violationBrowserHide
	violationBrowserShow -tool Other -type NarrowChannel
### Setting for view
	setDrawView fplan
#setLayerPreference node_blockage -isVisible 0
	setLayerPreference screen -isVisible 0
	setLayerPreference node_layer -isVisible 0
	setLayerPreference violation -isVisible 1
	setLayerPreference node_module -isVisible 0
	violationBrowserShow
	uiSet main -geometry [expr (int (ceil ([dbGet top.fPlan.box_sizex] / [dbGet top.fPlan.box_sizey]) * 1440))]x1440
	fit
	set Snapshot "[pwd]/Snapshot"
	check_dir $Snapshot
	set Snapshot_dir "[pwd]/Snapshot/narrow"
	check_dir $Snapshot_dir
	file delete -force  $Snapshot_dir/*
	set checktype "NarrowChannel"
	set i 0
	dumpToGIF ${Snapshot_dir}/${checktype}.${i}.gif ; # Full screen
	foreach box [dbShape [dbGet [dbGet top.markers {.userType == "NarrowChannel"} ].box -e]] {incr i ;zoomBox $box ; win ; dumpToGIF ${Snapshot_dir}/${checktype}.${i}.gif }

}
proc convert_camel_to_words {input_string} {
    set result ""
    for {set i 0} {$i < [string length $input_string]} {incr i} {
        set char [string index $input_string $i]
        # add space if there is a uppercase
        if {[regexp {[A-Z]} $char] && $i > 0} {
            append result " " $char
        } else {
            append result $char
        }
    }
    return $result
}
proc clarifySubType {listSubType} {
	set clarifySubType []
	foreach i $listSubType {
		 regsub {^SP} $i "" i_temp
   		 regsub {Violation$} $i_temp "" i_temp
		#regsub $i_temp "SP" "" i_temp
		if {[regexp "EndCap" $i_temp]  } {
			lappend clarifySubType [convert_camel_to_words $i_temp]
		} elseif {[regexp "OutOfCore" $i_temp]} {
			lappend clarifySubType "Out Of Core Area"
		} elseif {[regexp "Overlap" $i_temp]} {
			lappend clarifySubType "Overlap Instance"
		} else {
			lappend clarifySubType $i_temp
		}
	} 
	return $clarifySubType
}
set Snapshot_dir "[pwd]/Snapshot/"
check_dir $Snapshot_dir

proc export_gif {type} {
### Show only NarrowChannel markers
	setLayerPreference screen -isVisible 0
	set type_Marker [dbget top.markers.subType  -u -e]
	set clarify_Marker [clarifySubType $type_Marker]
	#violationBrowserHide
	set type_and_dir []
### Setting for view
	setDrawView fplan
	setLayerPreference node_blockage -isVisible 0
	#setLayerPreference node_layer -isVisible 0
	setLayerPreference violation -isVisible 1
	setLayerPreference node_module -isVisible 0
	uiSet main -geometry [expr (int (ceil ([dbGet top.fPlan.box_sizex] / [dbGet top.fPlan.box_sizey]) * 1440))]x1440
	fit
	
	set Snapshot_dir "[pwd]/Snapshot/$type"
	check_dir $Snapshot_dir
	#rm -f -r $Snapshot_dir/*
	#set checktype "NarrowChannel"
	set inn 0
	dumpToGIF ${Snapshot_dir}/${type}.${inn}.gif ; # Full screen

	foreach c $clarify_Marker i $type_Marker {
		set local []
		violationBrowserHide
		incr inn ;
		violationBrowserShow  -subtype "$c"
		win
		fit
		check_dir "${Snapshot_dir}/$i"
		file delete -force ${Snapshot_dir}/$i/*
		dumpToGIF ${Snapshot_dir}/$i/${i}.${inn}.gif
		lappend local [pwd]/$Snapshot_dir/$c 
		lappend local "${Snapshot_dir}/$i/${i}.${inn}.gif"
		lappend type_and_dir $local
	}
	return $type_and_dir
}
## EndCap Verification
puts $fw  "##---- INFO ---- ## Check EndCap qualification \n "
clearDrc
incr stt
verifyEndCap
set dir_CP [export_gif "EndCap"]
set drcEndcap [summaryDrc]
if {[lindex [lindex $drcEndcap 0] 0] == "0x0" && [llength $drcEndcap] == 1} {
	puts $fw "##---- INFO ---- ## Congratulation !!! Endcap Verification clean !!!! ^-^" 
	puts $fw_csv "$stt,EndCap,PASS,[pwd]/${vars(rpt_dir)}/verify_end_cap.rpt,N/A"
	} else {
	puts $fw  "##---- ERROR ---- ## Endcap Verification is not clean !!!!!! Here is the summary list of EndCap Drc " 
	puts $fw_csv "$stt,EndCap,FAIL,[pwd]/${vars(rpt_dir)}/verify_end_cap.rpt,[pwd]/Snapshot/EndCap" 
	foreach drc $drcEndcap {
		puts $fw "##---- ERROR ---- ## DRC name [lindex $drc 0] --- number of drc violations ---> [lindex $drc 1]"
	}
}
puts $fw  "#---- INFO ---- ## for further info in EndCap DRC , check this link [pwd]/${vars(rpt_dir)}/verify_end_cap.rpt \n\n\n"

## Well Tap Verification
puts $fw  "##---- INFO ---- ## Check WellTap qualification \n"
clearDrc
incr stt
#source $vars(script_root)/utility/$vars(node)/welltap.tcl
verifyWellTap -cell TAPCELLBWP240H8P57CPDSVT -rule 50 -avoidAbutment -siteOffset 3 
set dir_CP [export_gif "WellTap"]

#dumpToGIF [pwd]/${vars(rpt_dir)}/verify_well_tap.gif
#verifyWellTap -cell $vars(welltaps) -rule $vars(welltaps,verify_rule) -avoidAbutment -siteOffset 3 
set drcWellTap [summaryDrc]
if {[lindex [lindex $drcWellTap 0] 0] == "0x0" && [llength $drcWellTap] == 1} {
	puts $fw "##---- INFO ---- ## Congratulati/home/t_FX61AA021A_PR/FX61AA021A/PartitionPR/balboa_snic_top_Vinhne/R1P0b_newFlow/FDI/kw_balboa_top_grovf_rdma_ip_w_ram_0/sample_AC_release_FP_SDC01202026_v1/pron !!! WellTap Verification clean !!!! ^-^"
        puts $fw_csv "$stt,WellTap,PASS,[pwd]/${vars(rpt_dir)}/verify_well_tap.rpt,N/A" 
	} else {
        puts $fw  "##---- ERROR ---- ## WellTap Verification is not clean !!!! >\"< !! Here is the summary list of WellTap Drc "
        puts $fw_csv "$stt,WellTap,FAIL,[pwd]/${vars(rpt_dir)}/verify_well_tap.rpt,[pwd]/Snapshot/WellTap" 
	foreach drc $drcWellTap {
                puts $fw  "##---- ERROR ---- ## DRC name [lindex $drc 0] --- number of drc violations ---> [lindex $drc 1]"
        }
}
puts $fw  "##---- INFO ---- ## for further info in WellTap DRC , check this link [pwd]/${vars(rpt_dir)}/verify_well_tap.rpt \n\n\n"
puts $fw  "##---- INFO ---- ## Check Placement  qualification \n"
clearDrc
## CheckPlace Verification
incr stt
checkPlace > $vars(rpt_dir)/checkPlace.rpt
set dir_CP [export_gif "CheckPlace"]
set drcPlacement [summaryDrc]
if {[lindex [lindex $drcPlacement 0] 0] == "0x0" && [llength $drcPlacement] == 1} {
	puts $fw  "##---- INFO ---- ## Congratulation !!! Placement Verification clean !!!! ^-^ \n"
	 puts $fw_csv "$stt,CheckPlace ,PASS,[pwd]/$vars(rpt_dir)/checkPlace.rpt,[pwd]/Snapshot/CheckPlace"
} else {
    #    puts $fw_csv "$stt,CheckPlace ,FAIL,[pwd]/$vars(rpt_dir)/checkPlace.rpt,[pwd]/Snapshot/CheckPlace "
	puts $fw_csv "$stt,CheckPlace ,FAIL,[pwd]/$vars(rpt_dir)/checkPlace.rpt,[pwd]/Snapshot/CheckPlace "

#------------->> Check OutCore
	set fwt [open [pwd]/$vars(rpt_dir)/listOutCore.rpt w]
	puts $fw  "----------------> ##---- INFO ---- ## Outcore checking !!!!!!!"
	set inst_outcore [list]
	foreach pointer [dbGet top.markers.subType SPOutOfCoreViolation -p] {
	        set data_pointer [dbGet ${pointer}.message]
        	lappend inst_outcore [lindex $data_pointer 1]
	}
	if {[llength $inst_outcore] == 1 && [lindex [lindex $inst_outcore 0] 0] == ""} {
		puts $fw  "##---- INFO ---- ## No Instance OutCore Violation ^-^ !"
		puts $fw_csv "$stt,OutCore Instace,PASS,[pwd]/$vars(rpt_dir)/listOutCore.rpt ,N/A"
	} else {
        	puts $fw_csv "$stt,OutCore instance,FAIL,[pwd]/$vars(rpt_dir)/listOutCore.rpt,[pwd]/Snapshot/CheckPlace/SPOutOfCoreViolation"
		puts $fw  "##---- ERROR ---- ## OutCore Instance Exist >-< !!Total of [llength $inst_outcore] viols ! Here by the List all Instance outCore  ! \n"
        	puts $fw $inst_outcore
		puts $fwt $inst_outcore 
	}	
	close $fwt
#------------->> Check Ovelaped
	puts $fw "\n\n---------------->  ##---- INFO ---- ## Overlap checking  "
	set inst_overlap ""
 	set fwt [open [pwd]/$vars(rpt_dir)/listOverLap.rpt w]
	foreach pointer [dbGet top.markers.subType SPOverlapViolation -p] {
	        set data_pointer [dbGet ${pointer}.message]
        	lappend inst_overlap [lindex $data_pointer 1]
	}	
	if {[llength $inst_overlap] == 1 && [lindex [lindex $inst_overlap 0] 0] == ""} {
		puts $fw  "##---- INFO ---- ## No Instance Overlap Violation ^-^ !"
		puts $fw_csv "$stt,Overlap instance,PASS,N/A,N/A"
	} else {
       		puts $fw_csv "$stt,Overlap instance,FAIL, [pwd]/$vars(rpt_dir)/listOverLap.rpt,[pwd]/Snapshot/CheckPlace/SPOverlapViolation"
		puts $fw  "##---- ERROR ---- ## Overlaped Instance Exist >-< !!Total of [llength $inst_overlap] viols ! Here by the List all Instance Overlaped"
        	puts $fw  $inst_overlap 
		puts $fwt  $inst_overlap
	}

#------------>> Other 
#
puts $fw "\n\n---------------->  ##---- INFO ---- ## Other violation checking  "
	foreach drc $drcPlacement {
                puts $fw  "##---- ERROR ---- ## DRC name [lindex $drc 0] --- number of drc violations ---> [lindex $drc 1]"
        }
}
#------------->> Check Pin Assignment
incr stt
puts $fw "\n\n ##---- INFO ---- ## Check IO Pin Assignment!."
set flag_pin 0
checkPinAssignment -outFile [pwd]/${vars(rpt_dir)}/verify_pin.rpt -reportSameNetPinAsOverlap -report_violating_pin
set fwr [open "[pwd]/${vars(rpt_dir)}/verify_pin.rpt" r]
set file_data [read -nonewline $fwr]
close $fwr
set data [split $file_data "\n"]
set fwt [open "[pwd]/${vars(rpt_dir)}/pin_list_viol.rpt" w]
foreach line $data {
	if {[lindex $line 0] == "Illegally"} {set flag_pin 1;break}
}
set list_pin_violateLayer []
foreach pin [dbget top.terms.name] {
	if {[regexp [dbget [dbget top.terms.name -p1 $pin].layer] {M0 M1 M2 M3}]} {
		lappend list_pin_violateLayer $pin
		if {$flag_pin == 1} {
			set flag_pin 12
		} else {
			set flag_pin 2
		}
	}
}
puts $fwt $list_pin_violateLayer
close $fwt
if {$flag_pin == 0} {
	puts $fw_csv "$stt,Pin Assignment Verify,PASS, [pwd]/${vars(rpt_dir)}/verify_pin.rpt,N/A"
	puts $fw "##---- INFO ---- ## Pin Assignment PASS !"	
} elseif {$flag_pin == 1} { 
	puts $fw  "##---- ERROR ---- ## Pin Assignment  Illegal  >-< !! [pwd]/${vars(rpt_dir)}/verify_pin.rpt"
	puts $fw_csv "$stt,Pin Assignment Verify,Illegal, [pwd]/${vars(rpt_dir)}/verify_pin.rpt,N/A"
} elseif {$flag_pin == 2} {
	puts $fw_csv "$stt,Pin Assignment Verify,DP viols, [pwd]/${vars(rpt_dir)}/pin_list_viol.rpt,N/A"
        puts $fw  "##---- ERROR ---- ## Pin Assignment Double Patterning NOT qualified  >-< !!Here by the List all Pin is not Qualified \n [pwd]/${vars(rpt_dir)}/pin_list_viol.rpt"
} else {
        puts $fw  "##---- ERROR ---- ## Pin Assignment Double Patterning NOT qualified and some Illegal Pin >-< !!Here by the List all Pin is not Qualified \n [pwd]/${vars(rpt_dir)}/pin_list_viol.rpt \n Some illegal pin can checke in here [pwd]/${vars(rpt_dir)}/verify_pin.rpt"
		puts $fw_csv "$stt,Pin Assignment Verify,,Illegal/DP viols, [pwd]/${vars(rpt_dir)}/verify_pin.rpt \n [pwd]/${vars(rpt_dir)}/pin_list_viol,N/A"
}  
#------------>> Check Global Connect -----------------
incr stt
puts $fw "\n\n ##---- INFO ---- ## Check global connect (any inst missing global connect)."
set fw_glb [open [pwd]/${vars(rpt_dir)}/globalConnect.rpt w]
set isFullGlobalConnect 0
proc checkglobal {inst} {
	#if {[[llength [dbget [dbget -p top.insts.name $inst].pgInstTerms.name -e]] == 0]} {return 0} 
        if {[llength [dbget [dbget -p top.insts.name $inst].pgInstTerms.name -e]] != [llength [dbget [dbget -p top.insts.name $inst].pgInstTerms.net.name -e]]} {return 1} else {return 0}
}
set flag 0; set listFailedInsts []
foreach inst [dbget [dbget top.insts.cell.baseClass block -p2 ].name] {
        #if {[checkglobal $inst] == 1 || [dbget [dbget -p top.insts.name $inst].pgInstTerms.name] == "0x0"} { lappend listFailedInsts $inst ; set flag 1}
        if {[checkglobal $inst]} { lappend listFailedInsts $inst ; set flag 1}
}
foreach i $listFailedInsts {puts $fw_glb $i}
if {$flag == 0} {
	puts $fw "##---- INFO ---- ## All Block and Physical cells are already GLobal connected !"
	puts $fw_csv "$stt,Global Connect,PASS,#,N/A"
	} else {
        puts $fw_csv "$stt,Global Connect,FAIL,[pwd]/${vars(rpt_dir)}/globalConnect.rpt,N/A"
	puts $fw  "##---- ERROR ---- ## Global  Unconnected  Exist >-< !!Total of [llength $listFailedInsts] viols ! Here by the List all Instance Overlaped: ----> [pwd]/${vars(rpt_dir)}/globalConnect.rpt"
	puts $fw "---------------HereBy the list of [llength $listFailedInsts] have not global connected !!!!!-----------------"
	foreach i $listFailedInsts {puts $fw $i}
}
close $fw_glb
#------------>> Check Narrow 
clearDrc
incr stt
foreach box [dbGet [dbGet top.fPlan.rows {.box_sizex < 10}].box] {createMarker -bbox $box -type NarrowChannel}
set pgNets {VDD VSS} ;
foreach pgnet $pgNets {
        set pgnetBoxes [dbGet [dbGet [dbGet [dbGetNetByName $pgnet].sWires {.shape == "stripe"}].layer.name M11 -p2].box -e] ;
        foreach row [dbGet top.fPlan.rows {.box_sizex < 10}] {
                set num [llength [dbShape [dbShape [dbGet ${row}.box] SIZEX 1] AND $pgnetBoxes] ] ;
                if {$num < 2} {
                        createMarker -bbox [join [dbGet ${row}.box]] -type "Missing_[expr 2 - $num]_${pgnet}"
                }
        }
}
set checkChannelDrc [summaryDrc]
if {[lindex [lindex $checkChannelDrc 0] 0] == "0x0" && [llength $checkChannelDrc] == 1} {
	puts $fw  "##---- INFO ---- ## Congratulation !!! Placement Channel Verification is qualify !!!! ^-^ \n"
	puts $fw_csv "$stt,Channel Check,PASS,N/A,N/A "; 
} else {
        puts $fw "##---- WARNING! ---- ## BeWare !!! Placement Channel not qualify ! This possibly affect to other that cause DRCs  !!!! \n"
		#export_gif_quyen
	puts $fw_csv "$stt,Channel Check,Not Qualify,N/A,[pwd]/Snapshot/narrow"
}


clearDrc
#------------->> Check Drc -------------
puts $fw "\n\n##---- INFO ---- ## Drc Net checking "
incr stt
verify_drc -limit -1 -report ./${vars(rpt_dir)}/verify_drc.rpt -ignore_trial_route
setLayerPreference node_layer -isVisible 1
set dir_CP [export_gif "Drc"]

set net_shortCTS ""
set net_shortSignal_PG ""
set net_shortSignal_Signal ""
set net_shortPG_PG ""
foreach pointer [dbGet top.markers.subType *_Short -p] {
        set isBlock 0
        set data_pointer [dbGet ${pointer}.message]
        if  {[regexp "Blockage" $data_pointer]} {continue}

        if {[lindex $data_pointer 0] == "Special" && [lindex $data_pointer 6] == "Special"} {
                lappend net_shortPG_PG "Net Special: [lindex $data_pointer 4] , Net Special: [lindex $data_pointer 10] "
        }
        if {[lindex $data_pointer 0] == "Special" && [lindex $data_pointer 6] == "Regular"} {
                lappend net_shortSignal_PG "Net Special: [lindex $data_pointer 4] , Net Signal: [lindex $data_pointer 10] "
        }
        if {[lindex $data_pointer 0] == "Regular" && [lindex $data_pointer 6] == "Special"} {
                lappend net_shortSignal_PG "Net Signal: [lindex $data_pointer 4] , Net Special: [lindex $data_pointer 10] "
        }
        if {[lindex $data_pointer 0] == "Regular" && [lindex $data_pointer 6] == "Regular"} {
                lappend net_shortSignal_Signal "Net Signal: [lindex $data_pointer 4] , Net Signal: [lindex $data_pointer 10] "
        }
}
if {[llength $net_shortPG_PG] == 0} {

	puts $fw "##---- INFO ---- ## PG Net verify drc check PASS! "
	puts $fw_csv "$stt,PG Short Net,PASS,[pwd]/${vars(rpt_dir)}/verify_drc.rpt,[pwd]/Snapshot/Drc"} else {
	puts $fw "##---- ERROR ---- ## PG Net verify still ExistDrc ! "
	puts $fw "##->> Number of Nets with short violation in PG Net : [expr [llength $net_shortPG_PG]*2] "
	puts $fw_csv "$stt,PG Short Net,FAIL,[pwd]/${vars(rpt_dir)}/verify_drc.rpt,[pwd]/Snapshot/Drc"
}
setLayerPreference node_layer -isVisible 0

#------------->> Check PG connectivity -------------
#
clearDrc
incr stt
puts $fw "\n\n##---- INFO ---- ## Conectitivy PG checking "
verifyConnectivity -type special -noAntenna -noWeakConnect -noSoftPGConnect -report [pwd]/${vars(rpt_dir)}/verify_connect.rpt -error -1 -warning -1 -noUnroutedNet
set dir_CP [export_gif "Connectivity"]
set drcConnect [summaryDrc]
if {[lindex [lindex $drcConnect 0] 0] == "0x0" && [llength $drcConnect] == 1} {
        puts $fw "##---- INFO ---- ## Congratulation !!! Connectivity Verification clean !!!! ^-^"
        puts $fw_csv "$stt,Connectivity,PASS,[pwd]/${vars(rpt_dir)}/verify_connect.rpt ,N/A "
        } else {
        puts $fw  "##---- ERROR ---- ## Connectivity Verification is not clean !!!!  !! Here is the summary list of Connectivity  Drc "
        puts $fw_csv "$stt,Connectivity,FAIL,[pwd]/${vars(rpt_dir)}/verify_connect.rpt,[pwd]/Snapshot/Connectivity "
        foreach drc $drcConnect {
                puts $fw "##---- ERROR ---- ## DRC name [lindex $drc 0] --- number of drc violations ---> [lindex $drc 1]"
        }
}
puts $fw  "#---- INFO ---- ## for further info in PG connectivity DRC , check this link [pwd]/${vars(rpt_dir)}/verify_connect.rpt \n\n\n"
#------------->> Check PowerVia -------------
clearDrc
puts $fw "\n\n##---- INFO ---- ## Verify PowerVia checking "
verifyPowerVia -report [pwd]/${vars(rpt_dir)}/verify_PwrVia.rpt
setLayerPreference node_layer -isVisible 1

incr stt
set drcPwrVia [summaryDrc] 
set dir_CP [export_gif "PowerVia"]

if {[lindex [lindex $drcPwrVia 0] 0] == "0x0" && [llength $drcPwrVia] == 1} {
        puts $fw "##---- INFO ---- ## Congratulation !!! PowerVia verification clean !!!! ^-^"
        puts $fw_csv "$stt,PowerVia,PASS,[pwd]/${vars(rpt_dir)}//verify_PwrVia.rpt,N/A  "
        } else {
        puts $fw  "##---- ERROR ---- ## PowerVia Verification is not clean !!!! >< !! Here is the summary list of Connectivity  Drc "
        puts $fw_csv "$stt,PowerVia,FAIL,[pwd]/${vars(rpt_dir)}/verify_PwrVia.rpt ,[pwd]/Snapshot/PowerVia "
        foreach drc $drcPwrVia {
                puts $fw "##---- ERROR ---- ## DRC name [lindex $drc 0] --- number of drc violations ---> [lindex $drc 1]"
        }
}
setLayerPreference node_layer -isVisible 0

puts $fw  "#---- INFO ---- ## for further info in PowerVia DRC , check this link [pwd]/${vars(rpt_dir)}/verify_PwrVia.rpt \n\n\n"
##------------->> check tCIC
clearDrc

source /ASIC3/users/quyen_tong/WORK/N6/tCIC_check_only/run_tcic.tcl

incr stt
set drc_tCIC [summaryDrc]
if {[lindex [lindex $drc_tCIC 0] 0] == "0x0" && [llength $drc_tCIC] == 1} {
        puts $fw "##---- INFO ---- ## Congratulation !!! PowerVia verification clean !!!! ^-^"
        puts $fw_csv "$stt,tCIC,PASS,[pwd]/tCIC/tcic.rpt,N/A  "
        } else {
        puts $fw  "##---- ERROR ---- ## PowerVia Verification is not clean !!!! >\"< !! Here is the summary list of Connectivity  Drc "
        puts $fw_csv "$stt,tCIC,FAIL,[pwd]/tCIC/tcic.rpt,N/A"  
        foreach drc $drc_tCIC {
                puts $fw "##---- ERROR ---- ## DRC name [lindex $drc 0] --- number of drc violations ---> [lindex $drc 1]"
        }
}
puts $fw  "#---- INFO ---- ## for further info in PG connectivity DRC , check this link ${tCIC_dir}/tCIC_N6_General_v1d0_0_3a_Official_06252021.tcl \n\n\n"

###-END FP script check - close file write
close $fw
close $fw_csv
###--------------------------------Html------------
source /home/ASIC3/users/vinh_lam/practice/proc_tag.tcl
set outfile [open ./test.html w]
set fr [open ./test.csv r]
set file_data [read -nonewline $fr]
set data [split $file_data "\n"]
tag_DOCTYPE
tag_html
tag_head
        tag_link_css "/home/ASIC3/users/vinh_lam/practice/style.css"
tag_head_end
tag_body
        tag_main "table" "customers_table"
                tag_section "table__header"
                        tag_h "1"
                                put_content "FloorPlan CheckList"
                        tag_h_end "1"
						tag_h "2"
                                tag_a_href "[pwd]/test.rpt"
								put_content "Overall Report"
								tag_a_end
                        tag_h_end "2"
                tag_section_end
                tag_section "table__body"
                        tag_table
                                tag_table_head
                                        tag_table_tr
                                                tag_table_th
                                                        put_content "No."
                                                tag_table_th_end
                                                tag_table_th
                                                        put_content "Item"
                                                tag_table_th_end
                                                tag_table_th
                                                        put_content "Status"
                                                tag_table_th_end
                                                tag_table_th
                                                        put_content "Report"
                                                tag_table_th_end
												tag_table_th
                                                        put_content "Img"
                                                tag_table_th_end
                                        tag_table_tr_end
                                tag_table_head_end
				tag_table_body
					foreach line $data {
						set data_line [split $line ","]
						tag_table_tr
							tag_table_td
								put_content "[lindex $data_line 0]"
							tag_table_td_end
							tag_table_td
								put_content "[lindex $data_line 1]"
							tag_table_td_end
							tag_table_td
								if {[lindex $data_line 2] == "FAIL" || [lindex $data_line 2] == "Not Qualify" || [lindex $data_line 2] == "Illegal" } {
									tag_p "status cancelled"
										put_content "[lindex $data_line 2]"
									tag_p_end
								} else {
									tag_p "status delivered"
										put_content "[lindex $data_line 2]"	
									tag_p_end
								}
                            tag_table_td_end
							tag_table_td
								tag_a_href "[lindex $data_line 3]"
								tag_strong
                                        put_content "Report"
								tag_strong_end
								tag_a_end
                            tag_table_td_end
								tag_table_td
								
                                if {[lindex $data_line 4] == "N/A"} {put_content "N/A"} else {
								#	tag_ul
								#	set index 0
								#	foreach i [lindex $data_line 4] {
								#		incr index
								#		tag_li
											tag_a_href "[lindex $data_line 4]"
												put_content "Img"
											tag_a_end
								#		tag_li_end
								#	}
								#	tag_ul_end
								#}
								
										
								
                            tag_table_td_end
						tag_table_tr_end
					
					}
				tag_table_body_end
                        tag_table_end
                tag_section_end

        tag_main_end
	tag_script "/home/ASIC3/users/vinh_lam/practice/script.js"

tag_body_end
tag_html_end

close $outfile




puts "Done Script Check FloorPlan !!! ^_^"
puts "Run either command to check the result"
puts "vim [pwd]/test.rpt"
puts "vim [pwd]/test.csv"
puts "firefox [pwd]/test.html"
## recheck Verify
# checkPlace
# verify_drc -limit -1 -ignore_trial_route
# verifyConnectivity -type special -noAntenna -noWeakConnect -noSoftPGConnect  -error -1 -warning -1 -noUnroutedNet
