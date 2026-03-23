transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -2008 -work work {C:/Users/João/Documents/UNICAMP/MC613/VendingMachine/seletor_produto.vhd}
vcom -2008 -work work {C:/Users/João/Documents/UNICAMP/MC613/VendingMachine/selecionarValor.vhd}
vcom -2008 -work work {C:/Users/João/Documents/UNICAMP/MC613/VendingMachine/gerenciadorProduto.vhd}
vcom -2008 -work work {C:/Users/João/Documents/UNICAMP/MC613/VendingMachine/bin11_to_bcd4.vhd}
vcom -2008 -work work {C:/Users/João/Documents/UNICAMP/MC613/VendingMachine/bin2hex.vhd}
vcom -2008 -work work {C:/Users/João/Documents/UNICAMP/MC613/VendingMachine/VendingMachine.vhd}

vcom -2008 -work work {C:/Users/João/Documents/UNICAMP/MC613/VendingMachine/seletor_produto.vhd}
vcom -2008 -work work {C:/Users/João/Documents/UNICAMP/MC613/VendingMachine/../Testes/seletor_produto_tb.vhd}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cyclonev -L rtl_work -L work -voptargs="+acc"  seletor_produto_tb

add wave *
view structure
view signals
run -all
