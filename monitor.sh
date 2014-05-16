DIRETORIO_DESTINO_ARQUIVOS_JSON=/var/www/html;
JSON_MONITOR_MEMORIA=$DIRETORIO_DESTINO_ARQUIVOS_JSON/monitor-memoria.json;
TMP_MONITOR_MEMORIA=$DIRETORIO_DESTINO_ARQUIVOS_JSON/monitor-memoria.tmp;
JSON_MONITOR_SWAP=$DIRETORIO_DESTINO_ARQUIVOS_JSON/monitor-swap.json;
TMP_MONITOR_SWAP=$DIRETORIO_DESTINO_ARQUIVOS_JSON/monitor-swap.tmp;
JSON_MONITOR_HD=$DIRETORIO_DESTINO_ARQUIVOS_JSON/monitor-hd.json;
JSON_MONITOR_REDE=$DIRETORIO_DESTINO_ARQUIVOS_JSON/monitor-rede.json;
TMP_MONITOR_REDE=$DIRETORIO_DESTINO_ARQUIVOS_JSON/monitor-rede.tmp;
TMP_MONITOR_REDE_LEITURA_ANTERIOR=$DIRETORIO_DESTINO_ARQUIVOS_JSON/monitor-rede_la.tmp;

MEMORIA_TOTAL_INTEIRO=`ohai memory/total | grep [[:digit:]] | sed 's/["a-zA-Z ]//g'`;
MEMORIA_LIVRE_INTEIRO=`ohai memory/free | grep [[:digit:]] | sed 's/["a-zA-Z ]//g'`;
MEMORIA_LIVRE_INTEIRO_MB=$(($MEMORIA_LIVRE_INTEIRO / 1024));
MEMORIA_EM_USO_INTEIRO_MB=$((($MEMORIA_TOTAL_INTEIRO - $MEMORIA_LIVRE_INTEIRO) / 1024));
QUANTIDADE_MAXIMA_LEITURAS_MEMORIA=8;

SWAP_TOTAL_INTEIRO=`ohai memory/swap/total | grep [[:digit:]] | sed 's/["a-zA-Z ]//g'`;
SWAP_LIVRE_INTEIRO=`ohai memory/swap/free | grep [[:digit:]] | sed 's/["a-zA-Z ]//g'`;
SWAP_LIVRE_INTEIRO_MB=$(($SWAP_LIVRE_INTEIRO / 1024));
SWAP_EM_USO_INTEIRO_MB=$((($SWAP_TOTAL_INTEIRO - $SWAP_LIVRE_INTEIRO) / 1024));
QUANTIDADE_MAXIMA_LEITURAS_SWAP=6;

HD_LIVRE_INTEIRO=`ohai filesystem | sed 's/"\/dev\/sda/"devsda/g' | jq '.devsda2 .kb_available' | sed 's/["a-zA-Z]//g'`;
HD_LIVRE_INTEIRO_GB=`echo "scale=1; $HD_LIVRE_INTEIRO / 1024 / 1024" | bc -l`;
HD_USO_INTEIRO=`ohai filesystem | sed 's/"\/dev\/sda/"devsda/g' | jq '.devsda2 .kb_used' | sed 's/["a-zA-Z]//g'`;
HD_USO_INTEIRO_GB=`echo "scale=1; $HD_USO_INTEIRO / 1024 / 1024" | bc -l`;

INTERFACE_REDE=eth1;
REDE_ENTRADA_INTEIRO_BYTES=`ohai counters/network/interfaces/$INTERFACE_REDE/rx/bytes | grep [[:digit:]] | sed 's/["a-zA-Z ]//g'`;
REDE_ENTRADA_INTEIRO_PACOTES=`ohai counters/network/interfaces/$INTERFACE_REDE/rx/packets | grep [[:digit:]] | sed 's/["a-zA-Z ]//g'`;
REDE_SAIDA_INTEIRO_BYTES=`ohai counters/network/interfaces/$INTERFACE_REDE/tx/bytes | grep [[:digit:]] | sed 's/["a-zA-Z ]//g'`;
REDE_SAIDA_INTEIRO_PACOTES=`ohai counters/network/interfaces/$INTERFACE_REDE/tx/packets | grep [[:digit:]] | sed 's/["a-zA-Z ]//g'`;
QUANTIDADE_MAXIMA_LEITURAS_REDE=8;

HORA_LEITURA=`date +%H`;
MINUTO_LEITURA=`date +%M`;

if [ ! -f $JSON_MONITOR_MEMORIA ]; then
	echo "{" 																																																								>  $JSON_MONITOR_MEMORIA;
	echo "    \"cols\": [" 																																																					>> $JSON_MONITOR_MEMORIA;
	echo "            {\"id\": \"tempo\", \"label\": \"Tempo\", \"type\": \"string\"}," 																																					>> $JSON_MONITOR_MEMORIA;
	echo "            {\"id\": \"memoriaLivre\", \"label\": \"Memória RAM Livre\", \"type\": \"number\"}," 																																	>> $JSON_MONITOR_MEMORIA;
	echo "            {\"id\": \"memoriaUso\", \"label\": \"Memória RAM em Uso\", \"type\": \"number\"}" 																																	>> $JSON_MONITOR_MEMORIA;
	echo "    ]," 																																																							>> $JSON_MONITOR_MEMORIA;
	echo "    \"rows\": [" 																																																					>> $JSON_MONITOR_MEMORIA;
	echo "            {\"c\":[{\"v\": \"$HORA_LEITURA:$MINUTO_LEITURA\"}, {\"v\": $MEMORIA_LIVRE_INTEIRO_MB, \"f\": \"$MEMORIA_LIVRE_INTEIRO_MB MiB\"}, {\"v\": $MEMORIA_EM_USO_INTEIRO_MB, \"f\": \"$MEMORIA_EM_USO_INTEIRO_MB MiB\"}]}" 	>> $JSON_MONITOR_MEMORIA;
	echo "    ]" 																																																							>> $JSON_MONITOR_MEMORIA;
	echo "}" 																																																								>> $JSON_MONITOR_MEMORIA;
else
	QUANTIDADE_BYTES_TRUNCAR=`tail -n 2 $JSON_MONITOR_MEMORIA | wc -c`;
	QUANTIDADE_BYTES_TRUNCAR_ARQUIVO=$(($QUANTIDADE_BYTES_TRUNCAR + 1));

	truncate -s -$QUANTIDADE_BYTES_TRUNCAR_ARQUIVO $JSON_MONITOR_MEMORIA;

	echo "," 																																																								>> $JSON_MONITOR_MEMORIA;
	echo "            {\"c\":[{\"v\": \"$HORA_LEITURA:$MINUTO_LEITURA\"}, {\"v\": $MEMORIA_LIVRE_INTEIRO_MB, \"f\": \"$MEMORIA_LIVRE_INTEIRO_MB MiB\"}, {\"v\": $MEMORIA_EM_USO_INTEIRO_MB, \"f\": \"$MEMORIA_EM_USO_INTEIRO_MB MiB\"}]}" 	>> $JSON_MONITOR_MEMORIA;
	echo "    ]" 																																																							>> $JSON_MONITOR_MEMORIA;
	echo "}" 																																																								>> $JSON_MONITOR_MEMORIA;

	QUANTIDADE_LEITURAS=`cat $JSON_MONITOR_MEMORIA | grep '}]}' | wc -l`;

	if [ "$QUANTIDADE_LEITURAS" -gt "$QUANTIDADE_MAXIMA_LEITURAS_MEMORIA" ]; then
		echo "{" 																									>  $TMP_MONITOR_MEMORIA;
		echo "    \"cols\": [" 																						>> $TMP_MONITOR_MEMORIA;
		echo "            {\"id\": \"tempo\", \"label\": \"Tempo\", \"type\": \"string\"}," 						>> $TMP_MONITOR_MEMORIA;
		echo "            {\"id\": \"memoriaLivre\", \"label\": \"Memória RAM Livre\", \"type\": \"number\"}," 		>> $TMP_MONITOR_MEMORIA;
		echo "            {\"id\": \"memoriaUso\", \"label\": \"Memória RAM em Uso\", \"type\": \"number\"}" 		>> $TMP_MONITOR_MEMORIA;
		echo "    ]," 																								>> $TMP_MONITOR_MEMORIA;
		echo "    \"rows\": [" 																						>> $TMP_MONITOR_MEMORIA;
		
		sed '1,8d' $JSON_MONITOR_MEMORIA >> $TMP_MONITOR_MEMORIA;

		mv $TMP_MONITOR_MEMORIA $JSON_MONITOR_MEMORIA;
	fi
fi

if [ ! -f $JSON_MONITOR_SWAP ]; then
	echo "{" 																																																					>  $JSON_MONITOR_SWAP;
	echo "    \"cols\": [" 																																																		>> $JSON_MONITOR_SWAP;
	echo "            {\"id\": \"tempo\", \"label\": \"Tempo\", \"type\": \"string\"}," 																																		>> $JSON_MONITOR_SWAP;
	echo "            {\"id\": \"swapLivre\", \"label\": \"SWAP Livre\", \"type\": \"number\"}," 																																>> $JSON_MONITOR_SWAP;
	echo "            {\"id\": \"swapUso\", \"label\": \"SWAP em Uso\", \"type\": \"number\"}" 																																	>> $JSON_MONITOR_SWAP;
	echo "    ]," 																																																				>> $JSON_MONITOR_SWAP;
	echo "    \"rows\": [" 																																																		>> $JSON_MONITOR_SWAP;
	echo "            {\"c\":[{\"v\": \"$HORA_LEITURA:$MINUTO_LEITURA\"}, {\"v\": $SWAP_LIVRE_INTEIRO_MB, \"f\": \"$SWAP_LIVRE_INTEIRO_MB MiB\"}, {\"v\": $SWAP_EM_USO_INTEIRO_MB, \"f\": \"$SWAP_EM_USO_INTEIRO_MB MiB\"}]}" 	>> $JSON_MONITOR_SWAP;
	echo "    ]" 																																																				>> $JSON_MONITOR_SWAP;
	echo "}" 																																																					>> $JSON_MONITOR_SWAP;
else
	QUANTIDADE_BYTES_TRUNCAR=`tail -n 2 $JSON_MONITOR_SWAP | wc -c`;
	QUANTIDADE_BYTES_TRUNCAR_ARQUIVO=$(($QUANTIDADE_BYTES_TRUNCAR + 1));

	truncate -s -$QUANTIDADE_BYTES_TRUNCAR_ARQUIVO $JSON_MONITOR_SWAP;

	echo "," 																																																					>> $JSON_MONITOR_SWAP;
	echo "            {\"c\":[{\"v\": \"$HORA_LEITURA:$MINUTO_LEITURA\"}, {\"v\": $SWAP_LIVRE_INTEIRO_MB, \"f\": \"$SWAP_LIVRE_INTEIRO_MB MiB\"}, {\"v\": $SWAP_EM_USO_INTEIRO_MB, \"f\": \"$SWAP_EM_USO_INTEIRO_MB MiB\"}]}" 	>> $JSON_MONITOR_SWAP;
	echo "    ]" 																																																				>> $JSON_MONITOR_SWAP;
	echo "}" 																																																					>> $JSON_MONITOR_SWAP;

	QUANTIDADE_LEITURAS=`cat $JSON_MONITOR_SWAP | grep '}]}' | wc -l`;

	if [ "$QUANTIDADE_LEITURAS" -gt "$QUANTIDADE_MAXIMA_LEITURAS_SWAP" ]; then
		echo "{" 																							>  $TMP_MONITOR_SWAP;
		echo "    \"cols\": [" 																				>> $TMP_MONITOR_SWAP;
		echo "            {\"id\": \"tempo\", \"label\": \"Tempo\", \"type\": \"string\"}," 				>> $TMP_MONITOR_SWAP;
		echo "            {\"id\": \"swapLivre\", \"label\": \"SWAP Livre\", \"type\": \"number\"},"		>> $TMP_MONITOR_SWAP;
		echo "            {\"id\": \"swapUso\", \"label\": \"SWAP em Uso\", \"type\": \"number\"}" 			>> $TMP_MONITOR_SWAP;
		echo "    ]," 																						>> $TMP_MONITOR_SWAP;
		echo "    \"rows\": [" 																				>> $TMP_MONITOR_SWAP;
		
		sed '1,8d' $JSON_MONITOR_SWAP >> $TMP_MONITOR_SWAP;

		mv $TMP_MONITOR_SWAP $JSON_MONITOR_SWAP;
	fi
fi

if [ ! -f $JSON_MONITOR_HD ]; then
	echo "{" 																												>  $JSON_MONITOR_HD;
	echo "    \"cols\": [" 																									>> $JSON_MONITOR_HD;
	echo "            {\"id\": \"nome\", \"type\": \"string\"}," 															>> $JSON_MONITOR_HD;
	echo "            {\"id\": \"valor\", \"type\": \"number\"}" 															>> $JSON_MONITOR_HD;
	echo "    ]," 																											>> $JSON_MONITOR_HD;
	echo "    \"rows\": [" 																									>> $JSON_MONITOR_HD;
	echo "            {\"c\":[{\"v\": \"HD Livre\"}, {\"v\": $HD_LIVRE_INTEIRO_GB, \"f\": \"$HD_LIVRE_INTEIRO_GB GiB\"}]}," >> $JSON_MONITOR_HD;
	echo "            {\"c\":[{\"v\": \"HD em Uso\"}, {\"v\": $HD_USO_INTEIRO_GB, \"f\": \"$HD_USO_INTEIRO_GB GiB\"}]}" 	>> $JSON_MONITOR_HD;
	echo "    ]" 																											>> $JSON_MONITOR_HD;
	echo "}" 																												>> $JSON_MONITOR_HD;
else
	QUANTIDADE_BYTES_TRUNCAR=`tail -n 4 $JSON_MONITOR_HD | wc -c`;
	QUANTIDADE_BYTES_TRUNCAR_ARQUIVO=$QUANTIDADE_BYTES_TRUNCAR;

	truncate -s -$QUANTIDADE_BYTES_TRUNCAR_ARQUIVO $JSON_MONITOR_HD;

	echo "            {\"c\":[{\"v\": \"HD Livre\"}, {\"v\": $HD_LIVRE_INTEIRO_GB, \"f\": \"$HD_LIVRE_INTEIRO_GB GiB\"}]}," >> $JSON_MONITOR_HD;
	echo "            {\"c\":[{\"v\": \"HD em Uso\"}, {\"v\": $HD_USO_INTEIRO_GB, \"f\": \"$HD_USO_INTEIRO_GB GiB\"}]}" 	>> $JSON_MONITOR_HD;
	echo "    ]" 																											>> $JSON_MONITOR_HD;
	echo "}" 																												>> $JSON_MONITOR_HD;
fi

if [ ! -f $JSON_MONITOR_REDE ]; then
	echo "{" 																															>  $JSON_MONITOR_REDE;
	echo "    \"cols\": [" 																												>> $JSON_MONITOR_REDE;
	echo "            {\"id\": \"tempo\", \"label\": \"Tempo\", \"type\": \"string\"}," 												>> $JSON_MONITOR_REDE;
	echo "            {\"id\": \"trafegoEntrada\", \"label\": \"Tráfego de Entrada\", \"type\": \"number\"}," 							>> $JSON_MONITOR_REDE;
	echo "            {\"id\": \"trafegoSaida\", \"label\": \"Tráfego de Saída\", \"type\": \"number\"}" 								>> $JSON_MONITOR_REDE;
	echo "    ]," 																														>> $JSON_MONITOR_REDE;
	echo "    \"rows\": [" 																												>> $JSON_MONITOR_REDE;
	echo "            {\"c\":[{\"v\": \"$HORA_LEITURA:$MINUTO_LEITURA\"}, {\"v\": 0, \"f\": \"0 B\"}, {\"v\": 0, \"f\": \"0 B\"}]}" 	>> $JSON_MONITOR_REDE;
	echo "    ]" 																														>> $JSON_MONITOR_REDE;
	echo "}" 																															>> $JSON_MONITOR_REDE;

	echo "$HORA_LEITURA$MINUTO_LEITURA"	>	$TMP_MONITOR_REDE_LEITURA_ANTERIOR; 
	echo "$REDE_ENTRADA_INTEIRO_BYTES"	>> 	$TMP_MONITOR_REDE_LEITURA_ANTERIOR; 
	echo "$REDE_SAIDA_INTEIRO_BYTES"	>> 	$TMP_MONITOR_REDE_LEITURA_ANTERIOR;
else
	HORA_MINUTO_LEITURA_ANTERIOR=`sed -n 1p $TMP_MONITOR_REDE_LEITURA_ANTERIOR`;
	REDE_EIB_LEITURA_ANTERIOR=`sed -n 2p $TMP_MONITOR_REDE_LEITURA_ANTERIOR`;
	REDE_SIB_LEITURA_ANTERIOR=`sed -n 3p $TMP_MONITOR_REDE_LEITURA_ANTERIOR`;

	if [ "$(($HORA_LEITURA$MINUTO_LEITURA - $HORA_MINUTO_LEITURA_ANTERIOR))" -eq "1" ]; then
		REDE_ENTRADA_INTEIRO_BYTES_DIF=$(($REDE_ENTRADA_INTEIRO_BYTES - $REDE_EIB_LEITURA_ANTERIOR));
		REDE_SAIDA_INTEIRO_BYTES_DIF=$(($REDE_SAIDA_INTEIRO_BYTES - $REDE_SIB_LEITURA_ANTERIOR));

		echo "$HORA_LEITURA$MINUTO_LEITURA"	>	$TMP_MONITOR_REDE_LEITURA_ANTERIOR; 
		echo "$REDE_ENTRADA_INTEIRO_BYTES"	>> 	$TMP_MONITOR_REDE_LEITURA_ANTERIOR; 
		echo "$REDE_SAIDA_INTEIRO_BYTES"	>> 	$TMP_MONITOR_REDE_LEITURA_ANTERIOR;
	else 
		echo "$HORA_LEITURA$MINUTO_LEITURA"	>	$TMP_MONITOR_REDE_LEITURA_ANTERIOR; 
		echo "$REDE_ENTRADA_INTEIRO_BYTES"	>> 	$TMP_MONITOR_REDE_LEITURA_ANTERIOR; 
		echo "$REDE_SAIDA_INTEIRO_BYTES"	>> 	$TMP_MONITOR_REDE_LEITURA_ANTERIOR;

		REDE_ENTRADA_INTEIRO_BYTES_DIF=0;
		REDE_SAIDA_INTEIRO_BYTES_DIF=0;
	fi

	QUANTIDADE_BYTES_TRUNCAR=`tail -n 2 $JSON_MONITOR_REDE | wc -c`;
	QUANTIDADE_BYTES_TRUNCAR_ARQUIVO=$(($QUANTIDADE_BYTES_TRUNCAR + 1));

	truncate -s -$QUANTIDADE_BYTES_TRUNCAR_ARQUIVO $JSON_MONITOR_REDE;

	echo "," 																																																												>> $JSON_MONITOR_REDE;
	echo "            {\"c\":[{\"v\": \"$HORA_LEITURA:$MINUTO_LEITURA\"}, {\"v\": $REDE_ENTRADA_INTEIRO_BYTES_DIF, \"f\": \"$REDE_ENTRADA_INTEIRO_BYTES_DIF B\"}, {\"v\": $REDE_SAIDA_INTEIRO_BYTES_DIF, \"f\": \"$REDE_SAIDA_INTEIRO_BYTES_DIF B\"}]}" 	>> $JSON_MONITOR_REDE;
	echo "    ]" 																																																											>> $JSON_MONITOR_REDE;
	echo "}" 																																																												>> $JSON_MONITOR_REDE;

	QUANTIDADE_LEITURAS=`cat $JSON_MONITOR_REDE | grep '}]}' | wc -l`;

	if [ "$QUANTIDADE_LEITURAS" -gt "$QUANTIDADE_MAXIMA_LEITURAS_REDE" ]; then
		echo "{" 																									>  $TMP_MONITOR_REDE;
		echo "    \"cols\": [" 																						>> $TMP_MONITOR_REDE;
		echo "            {\"id\": \"tempo\", \"label\": \"Tempo\", \"type\": \"string\"}," 						>> $TMP_MONITOR_REDE;
		echo "            {\"id\": \"trafegoEntrada\", \"label\": \"Tráfego de Entrada\", \"type\": \"number\"}," 	>> $TMP_MONITOR_REDE;
		echo "            {\"id\": \"trafegoSaida\", \"label\": \"Tráfego de Saída\", \"type\": \"number\"}" 		>> $TMP_MONITOR_REDE;
		echo "    ]," 																								>> $TMP_MONITOR_REDE;
		echo "    \"rows\": [" 																						>> $TMP_MONITOR_REDE;
		
		sed '1,8d' $JSON_MONITOR_REDE >> $TMP_MONITOR_REDE;

		mv $TMP_MONITOR_REDE $JSON_MONITOR_REDE;
	fi
fi