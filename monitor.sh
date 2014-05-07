DIRETORIO_DESTINO_ARQUIVOS_JSON=/var/www/html;
JSON_MONITOR_MEMORIA_EM_USO=$DIRETORIO_DESTINO_ARQUIVOS_JSON/monitor-memoria_em_uso.json;

if [ ! -f $JSON_MONITOR_MEMORIA_EM_USO ]; then
	touch $JSON_MONITOR_MEMORIA_EM_USO;

	HORA_MINUTO_LEITURA=`date +%H:%M`;
	MEMORIA_EM_USO_STRING=`ohai memory/free | grep [[:digit:]]`;
	MEMORIA_EM_USO_INTEIRO=`echo $MEMORIA_EM_USO_STRING | sed 's/["a-zA-Z]//g'`;
	MEMORIA_EM_USO_INTEIRO_MB=`$(($MEMORIA_EM_USO_INTEIRO / 1024))`;

	echo "{" 																																		>> $JSON_MONITOR_MEMORIA_EM_USO;
	echo "    \"cols\": [" 																															>> $JSON_MONITOR_MEMORIA_EM_USO;
	echo "            {\"id\": \"tempo\", \"label\": \"Tempo\", \"type\": \"string\"}," 															>> $JSON_MONITOR_MEMORIA_EM_USO;
	echo "            {\"id\": \"memoria\", \"label\": \"Uso de Memória RAM\", \"type\": \"number\"}" 												>> $JSON_MONITOR_MEMORIA_EM_USO;
	echo "    ]," 																																	>> $JSON_MONITOR_MEMORIA_EM_USO;
	echo "    \"rows\": [" 																															>> $JSON_MONITOR_MEMORIA_EM_USO;
	echo "            {\"c\":[{\"v\": \"$HORA_MINUTO_LEITURA\"}, {\"v\": $MEMORIA_EM_USO_INTEIRO_MB, \"f\": \"$MEMORIA_EM_USO_INTEIRO_MB MB\"}]}" 	>> $JSON_MONITOR_MEMORIA_EM_USO;
	echo "    ]" 																																	>> $JSON_MONITOR_MEMORIA_EM_USO;
	echo "}" 																																		>> $JSON_MONITOR_MEMORIA_EM_USO;
fi