-- Script de inicialização do banco Zabbix
-- Este arquivo será executado automaticamente pelo MariaDB na primeira inicialização

CREATE DATABASE IF NOT EXISTS zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER IF NOT EXISTS 'zabbix'@'%' IDENTIFIED BY 'zabbix';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'%';
FLUSH PRIVILEGES;

-- O schema será importado automaticamente pelo container zabbix-server
-- na primeira execução quando detectar um banco vazio