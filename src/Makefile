coverage_it: simulate_it
	vcover report -html coverage.ucdb -htmldir covReport -details

simulate_it: compile_file 
	vsim -vopt work.expression -voptargs=+acc=npr -assertdebug -l module_name.log -coverage -c -do "coverage save -onexit -assert -directive -cvg -codeAll coverage.ucdb; run -all; exit"

compile_file:
	vlog -sv +acc +cover +fcover -l module_name.log *.sv

clean:
	rm -rf covReport/ work/ 
	rm coverage.ucdb
