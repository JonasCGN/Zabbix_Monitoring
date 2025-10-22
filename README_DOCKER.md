# Zabbix com Docker Compose

Este repositório contém um exemplo de orquestração completa para Zabbix 7.0 usando imagens oficiais e MariaDB, baseado no tutorial do README.md original.

## Arquivos incluídos:
- `docker-compose.yml` — orquestra todos os serviços com healthchecks
- `.env.example` — exemplo de variáveis de ambiente
- `Makefile` — automatiza comandos comuns
- `init-db.sql` — inicialização automática do banco
- `README_DOCKER.md` — esta documentação

## Uso rápido com Makefile:

```bash
# Configuração inicial (cria .env a partir do .env.example)
make setup

# Editar .env conforme necessário
nano .env

# Subir todos os serviços
make up

# Ver status
make status

# Ver logs
make logs

# Parar serviços
make down
```

## Uso manual (sem Makefile):

1. Copie o arquivo de exemplo para `.env` e edite as senhas/porta:

```bash
cp .env.example .env
# editar .env com um editor de texto
```

2. Subir os serviços:

```bash
docker compose up -d --build
```

3. Acesse a interface web em `http://localhost:8080` (ou a porta configurada em `.env`).

## ✅ Credenciais de Acesso

- **URL**: http://localhost:8080
- **Usuário**: Admin
- **Senha**: admin

> ℹ️ **Nota**: As credenciais também estão configuradas no arquivo `.env` como:
> - `ZABBIX_WEB_USER=Admin`
> - `ZABBIX_WEB_PASSWORD=admin`

## Funcionalidades implementadas:

✅ **Inicialização automática do banco** - O schema do Zabbix é importado automaticamente  
✅ **Healthchecks** - Todos os serviços têm verificação de saúde  
✅ **Dependências ordenadas** - Os serviços sobem na ordem correta  
✅ **Volumes persistentes** - Dados do banco são mantidos entre restarts  
✅ **Timezone configurável** - Configurado para America/Sao_Paulo  
✅ **Charset correto** - utf8mb4 conforme README original  

## Comandos úteis do Makefile:

```bash
make help      # Lista todos os comandos disponíveis
make setup     # Configuração inicial
make up        # Sobe serviços
make down      # Para serviços
make restart   # Reinicia serviços
make logs      # Mostra logs
make status    # Status dos containers
make test      # Testa se está funcionando
make backup    # Backup do banco
make clean     # Limpeza completa (CUIDADO!)
```

## Troubleshooting:

**Problema:** Container não sobe  
**Solução:** `make logs` para ver o erro específico

**Problema:** Web interface não carrega  
**Solução:** `make test` para verificar todos os serviços

**Problema:** Erro de permissão  
**Solução:** Verificar se o Docker está rodando e se o usuário tem permissões

## Comparação com o método manual (README.md):

| Método Manual | Docker Compose |
|---------------|----------------|
| ~15 comandos manuais | 1 comando (`make up`) |
| Configuração manual do PHP | Automático via variáveis |
| Instalação de pacotes no host | Isolado em containers |
| Backup manual | `make backup` |
| Dependente do OS | Funciona em qualquer OS com Docker |

## Próximos passos opcionais:
- Configurar TLS/SSL (HTTPS)
- Adicionar templates personalizados
- Configurar SNMP traps
- Monitoramento de logs
- Backup automático agendado