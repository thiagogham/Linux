#!/bin/bash
#
#   Descrição: Realiza Backup de Todos os Bancos de Dados (Postgres)
#   Autor: Thiago R. Gham
#   Data: 15-05-2016

echo -e "Inicio Programa " `date +%c`

DATA=`date +%Y-%m-%d`
FTP_HOST="host" 
FTP_NAME="user" 
FTP_PASS="pass" 
FTP_DIR="/backups/" 
TIME_BKCP=2
HOSTNAME="localhost"
USERNAME="postgres"
BACKUP_DIR="/backup/" 
MPUTSIM=""

#
#   Realiza o Backup de todos os Bancos de Dados
#
backup(){  
    echo -e "Inicio Backup Banco de Dados " `date +%c`
    echo -e "\n\nBackup Servidor $HOSTNAME\n"
    for DATABASE in `su - postgres -c 'psql postgres -At -c "SELECT datname FROM pg_database WHERE NOT datistemplate ORDER BY datname;"'`
    do
        echo -e "Banco de Dados: $DATABASE"
        echo -e "Inicio "`date +%c`
        su - postgres -c "pg_dump $DATABASE | gzip > $BACKUP_DIR$DATABASE-$DATA.sql.gz;"
        echo -e "Fim "`date +%c`
        echo -e ""
        MPUTSIM="$MPUTSIM y\r" 
    done
    echo -e "\nBackup de Todos os Bancos de Dados do Servidor $HOSTNAME concluidos\n"
    echo -e "-----------------------------------------------------------"
}
#
#   Envia para Servidor FTP
#
transferebk(){
    echo -e "Inicio Transferencia Backups " `date +%c`
    echo -e "\n\Transferencia dos Backups Servidor $FTP_HOST\n"
/usr/bin/expect <<EOF
    spawn ftp $FTP_HOST
    set timeout -1
     
    expect "Name"
    send -- "$FTP_NAME\r"
     
    expect "Password"
    send -- "$FTP_PASS\r"
 
    expect ">"
    send -- "cd $FTP_DIR\r"

    expect ">"
    send -- "lcd $BACKUP_DIR\r"

    expect ">"
    send -- "mput *\r $MPUTSIM"

    expect ">"
    send -- "bye\r"
EOF
    echo -e "\nTransferencia para Servidor $FTP_HOST concluida\n"
    echo -e "-----------------------------------------------------------"
}
#
#   Remove Backups Antigos
#
removeantigo(){
    echo -e "Inicio Remover Backups " `date +%c`
    find $BACKUP_DIR -name "*.gz" -ctime $TIME_BKCP -exec rm -f {} ";"
    if [ $? -eq 0 ] ; then
      echo -e "Arquivo de backup mais antigo eliminado com sucesso"
    else
      echo -e "Erro durante a busca e remoção do backup antigo"
    fi
    echo -e "\nRemover Backups concluido\n"
    echo -e "-----------------------------------------------------------"
}

backup
transferebk
removeantigo

echo -e "Fim "`date +%c`
