DIRETORIO_DESTINO_ARQUIVOS_JSON=/var/www/html;
JSON_MONITOR_MEMORIA=$DIRETORIO_DESTINO_ARQUIVOS_JSON/monitor-memoria.json;
TMP_MONITOR_MEMORIA=$DIRETORIO_DESTINO_ARQUIVOS_JSON/monitor-memoria.tmp;
JSON_MONITOR_SWAP=$DIRETORIO_DESTINO_ARQUIVOS_JSON/monitor-swap.json;
TMP_MONITOR_SWAP=$DIRETORIO_DESTINO_ARQUIVOS_JSON/monitor-swap.tmp;

MEMORIA_TOTAL_STRING=`ohai memory/total | grep [[:digit:]]`;
MEMORIA_TOTAL_INTEIRO=`echo $MEMORIA_TOTAL_STRING | sed 's/["a-zA-Z]//g'`;
MEMORIA_LIVRE_STRING=`ohai memory/free | grep [[:digit:]]`;
MEMORIA_LIVRE_INTEIRO=`echo $MEMORIA_LIVRE_STRING | sed 's/["a-zA-Z]//g'`;
MEMORIA_LIVRE_INTEIRO_MB=$(($MEMORIA_LIVRE_INTEIRO / 1024));
MEMORIA_EM_USO_INTEIRO_MB=$((($MEMORIA_TOTAL_INTEIRO - $MEMORIA_LIVRE_INTEIRO) / 1024));
QUANTIDADE_MAXIMA_LEITURAS_MEMORIA=8;

SWAP_TOTAL_STRING=`ohai memory/swap/total | grep [[:digit:]]`;
SWAP_TOTAL_INTEIRO=`echo $SWAP_TOTAL_STRING | sed 's/["a-zA-Z]//g'`;
SWAP_LIVRE_STRING=`ohai memory/swap/free | grep [[:digit:]]`;
SWAP_LIVRE_INTEIRO=`echo $SWAP_LIVRE_STRING | sed 's/["a-zA-Z]//g'`;
SWAP_LIVRE_INTEIRO_MB=$(($SWAP_LIVRE_INTEIRO / 1024));
SWAP_EM_USO_INTEIRO_MB=$((($SWAP_TOTAL_INTEIRO - $SWAP_LIVRE_INTEIRO) / 1024));
QUANTIDADE_MAXIMA_LEITURAS_SWAP=6;

HORA_MINUTO_LEITURA=`date +%H:%M`;

if [ ! -f $JSON_MONITOR_MEMORIA ]; then
	echo "{" 																																																						>  $JSON_MONITOR_MEMORIA;
	echo "    \"cols\": [" 																																																			>> $JSON_MONITOR_MEMORIA;
	echo "            {\"id\": \"tempo\", \"label\": \"Tempo\", \"type\": \"string\"}," 																																			>> $JSON_MONITOR_MEMORIA;
	echo "            {\"id\": \"memoriaLivre\", \"label\": \"Memória RAM Livre\", \"type\": \"number\"}," 																															>> $JSON_MONITOR_MEMORIA;
	echo "            {\"id\": \"memoriaUso\", \"label\": \"Memória RAM em Uso\", \"type\": \"number\"}" 																															>> $JSON_MONITOR_MEMORIA;
	echo "    ]," 																																																					>> $JSON_MONITOR_MEMORIA;
	echo "    \"rows\": [" 																																																			>> $JSON_MONITOR_MEMORIA;
	echo "            {\"c\":[{\"v\": \"$HORA_MINUTO_LEITURA\"}, {\"v\": $MEMORIA_LIVRE_INTEIRO_MB, \"f\": \"$MEMORIA_LIVRE_INTEIRO_MB MiB\"}, {\"v\": $MEMORIA_EM_USO_INTEIRO_MB, \"f\": \"$MEMORIA_EM_USO_INTEIRO_MB MiB\"}]}" 	>> $JSON_MONITOR_MEMORIA;
	echo "    ]" 																																																					>> $JSON_MONITOR_MEMORIA;
	echo "}" 																																																						>> $JSON_MONITOR_MEMORIA;
else
	QUANTIDADE_BYTES_TRUNCAR=`tail -n 2 $JSON_MONITOR_MEMORIA | wc -c`;
	QUANTIDADE_BYTES_TRUNCAR_ARQUIVO=$(($QUANTIDADE_BYTES_TRUNCAR + 1));

	truncate -s -$QUANTIDADE_BYTES_TRUNCAR_ARQUIVO $JSON_MONITOR_MEMORIA;

	echo "," 																																																						>> $JSON_MONITOR_MEMORIA;
	echo "            {\"c\":[{\"v\": \"$HORA_MINUTO_LEITURA\"}, {\"v\": $MEMORIA_LIVRE_INTEIRO_MB, \"f\": \"$MEMORIA_LIVRE_INTEIRO_MB MiB\"}, {\"v\": $MEMORIA_EM_USO_INTEIRO_MB, \"f\": \"$MEMORIA_EM_USO_INTEIRO_MB MiB\"}]}" 	>> $JSON_MONITOR_MEMORIA;
	echo "    ]" 																																																					>> $JSON_MONITOR_MEMORIA;
	echo "}" 																																																						>> $JSON_MONITOR_MEMORIA;

	QUANTIDADE_LEITURAS=`cat $JSON_MONITOR_MEMORIA | grep '}]}' | wc -l`;

	if [ "$QUANTIDADE_LEITURAS" -gt "$QUANTIDADE_MAXIMA_LEITURAS_MEMORIA" ]; then
		echo "{" 																																																					>  $TMP_MONITOR_MEMORIA;
		echo "    \"cols\": [" 																																																		>> $TMP_MONITOR_MEMORIA;
		echo "            {\"id\": \"tempo\", \"label\": \"Tempo\", \"type\": \"string\"}," 																																		>> $TMP_MONITOR_MEMORIA;
		echo "            {\"id\": \"memoriaLivre\", \"label\": \"Memória RAM Livre\", \"type\": \"number\"}," 																														>> $TMP_MONITOR_MEMORIA;
		echo "            {\"id\": \"memoriaUso\", \"label\": \"Memória RAM em Uso\", \"type\": \"number\"}" 																														>> $TMP_MONITOR_MEMORIA;
		echo "    ]," 																																																				>> $TMP_MONITOR_MEMORIA;
		echo "    \"rows\": [" 																																																		>> $TMP_MONITOR_MEMORIA;
		
		sed '1,8d' $JSON_MONITOR_MEMORIA >> $TMP_MONITOR_MEMORIA;

		mv $TMP_MONITOR_MEMORIA $JSON_MONITOR_MEMORIA;
	fi
fi

if [ ! -f $JSON_MONITOR_SWAP ]; then
	echo "{" 																																																			>  $JSON_MONITOR_SWAP;
	echo "    \"cols\": [" 																																																>> $JSON_MONITOR_SWAP;
	echo "            {\"id\": \"tempo\", \"label\": \"Tempo\", \"type\": \"string\"}," 																																>> $JSON_MONITOR_SWAP;
	echo "            {\"id\": \"swapLivre\", \"label\": \"SWAP Livre\", \"type\": \"number\"}," 																														>> $JSON_MONITOR_SWAP;
	echo "            {\"id\": \"swapUso\", \"label\": \"SWAP em Uso\", \"type\": \"number\"}" 																															>> $JSON_MONITOR_SWAP;
	echo "    ]," 																																																		>> $JSON_MONITOR_SWAP;
	echo "    \"rows\": [" 																																																>> $JSON_MONITOR_SWAP;
	echo "            {\"c\":[{\"v\": \"$HORA_MINUTO_LEITURA\"}, {\"v\": $SWAP_LIVRE_INTEIRO_MB, \"f\": \"$SWAP_LIVRE_INTEIRO_MB MiB\"}, {\"v\": $SWAP_EM_USO_INTEIRO_MB, \"f\": \"$SWAP_EM_USO_INTEIRO_MB MiB\"}]}" 	>> $JSON_MONITOR_SWAP;
	echo "    ]" 																																																		>> $JSON_MONITOR_SWAP;
	echo "}" 																																																			>> $JSON_MONITOR_SWAP;
else
	QUANTIDADE_BYTES_TRUNCAR=`tail -n 2 $JSON_MONITOR_SWAP | wc -c`;
	QUANTIDADE_BYTES_TRUNCAR_ARQUIVO=$(($QUANTIDADE_BYTES_TRUNCAR + 1));

	truncate -s -$QUANTIDADE_BYTES_TRUNCAR_ARQUIVO $JSON_MONITOR_SWAP;

	echo "," 																																																			>> $JSON_MONITOR_SWAP;
	echo "            {\"c\":[{\"v\": \"$HORA_MINUTO_LEITURA\"}, {\"v\": $SWAP_LIVRE_INTEIRO_MB, \"f\": \"$SWAP_LIVRE_INTEIRO_MB MiB\"}, {\"v\": $SWAP_EM_USO_INTEIRO_MB, \"f\": \"$SWAP_EM_USO_INTEIRO_MB MiB\"}]}" 	>> $JSON_MONITOR_SWAP;
	echo "    ]" 																																																		>> $JSON_MONITOR_SWAP;
	echo "}" 																																																			>> $JSON_MONITOR_SWAP;

	QUANTIDADE_LEITURAS=`cat $JSON_MONITOR_SWAP | grep '}]}' | wc -l`;

	if [ "$QUANTIDADE_LEITURAS" -gt "$QUANTIDADE_MAXIMA_LEITURAS_SWAP" ]; then
		echo "{" 																																																		>  $TMP_MONITOR_SWAP;
		echo "    \"cols\": [" 																																															>> $TMP_MONITOR_SWAP;
		echo "            {\"id\": \"tempo\", \"label\": \"Tempo\", \"type\": \"string\"}," 																															>> $TMP_MONITOR_SWAP;
		echo "            {\"id\": \"swapLivre\", \"label\": \"SWAP Livre\", \"type\": \"number\"}," 																													>> $TMP_MONITOR_SWAP;
		echo "            {\"id\": \"swapUso\", \"label\": \"SWAP em Uso\", \"type\": \"number\"}" 																														>> $TMP_MONITOR_SWAP;
		echo "    ]," 																																																	>> $TMP_MONITOR_SWAP;
		echo "    \"rows\": [" 																																															>> $TMP_MONITOR_SWAP;
		
		sed '1,8d' $JSON_MONITOR_SWAP >> $TMP_MONITOR_SWAP;

		mv $TMP_MONITOR_SWAP $JSON_MONITOR_SWAP;
	fi
fi