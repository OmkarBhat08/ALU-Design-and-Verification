coverage_it: simulate_it
	vcover report -html coverage.ucdb -htmldir covReport -details

simulate_it: compile_file 
	vsim -vopt work.alu_tb -voptargs=+acc=npr -assertdebug -l alu_tb.log -coverage -c -do "coverage save -onexit -assert -directive -cvg -codeAll coverage.ucdb; run -all; exit"

compile_file:
	vlog -v +acc +cover +fcover -l alu_tb.log alu_tb.v

clean:
	rm -rf covReport/ work/ 
	rm coverage.ucdb
