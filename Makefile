# Makefile para automação do Zabbix com Docker Compose
# Baseado no tutorial do README.md

.PHONY: help setup up down restart logs status clean backup restore test

# Variáveis
COMPOSE_FILE := docker-compose.yml
ENV_FILE := .env
ENV_EXAMPLE := .env.example

# Cores para output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Ajuda - comando padrão
help:
	@echo "$(GREEN)Zabbix Docker Compose - Comandos Disponíveis:$(NC)"
	@echo ""
	@echo "  $(YELLOW)setup$(NC)     - Configuração inicial (copia .env.example para .env)"
	@echo "  $(YELLOW)up$(NC)        - Sobe todos os serviços em background"
	@echo "  $(YELLOW)down$(NC)      - Para e remove todos os containers"
	@echo "  $(YELLOW)restart$(NC)   - Reinicia todos os serviços"
	@echo "  $(YELLOW)logs$(NC)      - Mostra logs de todos os serviços"
	@echo "  $(YELLOW)status$(NC)    - Status de todos os containers"
	@echo "  $(YELLOW)test$(NC)      - Testa se os serviços estão funcionando"
	@echo "  $(YELLOW)clean$(NC)     - Remove containers, volumes e imagens (CUIDADO!)"
	@echo "  $(YELLOW)backup$(NC)    - Faz backup do banco de dados"
	@echo "  $(YELLOW)restore$(NC)   - Restaura backup do banco (ex: make restore BACKUP=backup.sql)"
	@echo "  $(YELLOW)reset-admin-password$(NC) - Reseta senha do Admin para 'admin'"
	@echo ""
	@echo "$(GREEN)Acesso Web:$(NC) http://localhost:8080 (usuário: Admin, senha: admin)"
	@echo "$(GREEN)Documentação:$(NC) README_DOCKER.md"

# Configuração inicial
setup:
	@echo "$(GREEN)Configurando ambiente inicial...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		cp $(ENV_EXAMPLE) $(ENV_FILE); \
		echo "$(YELLOW)Arquivo .env criado a partir do .env.example$(NC)"; \
		echo "$(YELLOW)Edite o arquivo .env conforme necessário antes de executar 'make up'$(NC)"; \
	else \
		echo "$(YELLOW)Arquivo .env já existe$(NC)"; \
	fi

# Subir serviços
up: setup
	@echo "$(GREEN)Subindo serviços Zabbix...$(NC)"
	docker compose up -d --build
	@echo "$(GREEN)Aguardando serviços ficarem saudáveis...$(NC)"
	@sleep 5
	@make status
	@echo "$(GREEN)Zabbix disponível em: http://localhost:8080$(NC)"
	@echo "$(YELLOW)Login: Admin / Senha: admin$(NC)"

# Parar serviços
down:
	@echo "$(RED)Parando serviços Zabbix...$(NC)"
	docker compose down

# Reiniciar serviços
restart:
	@echo "$(YELLOW)Reiniciando serviços...$(NC)"
	docker compose restart
	@make status

# Ver logs
logs:
	@echo "$(GREEN)Logs dos serviços (Ctrl+C para sair):$(NC)"
	docker compose logs -f

# Status dos containers
status:
	@echo "$(GREEN)Status dos containers:$(NC)"
	@docker compose ps
	@echo ""
	@echo "$(GREEN)Health status:$(NC)"
	@docker compose ps --format "table {{.Name}}\t{{.Status}}"

# Teste de funcionamento
test:
	@echo "$(GREEN)Testando serviços...$(NC)"
	@echo "Testando MariaDB..."
	@docker compose exec db mysqladmin ping -h localhost || echo "$(RED)MariaDB não está respondendo$(NC)"
	@echo "Testando Zabbix Server..."
	@docker compose exec zabbix-server zabbix_server -R config_cache_reload 2>/dev/null || echo "$(RED)Zabbix Server não está respondendo$(NC)"
	@echo "Testando Web Interface..."
	@curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8080/ || echo "$(RED)Web interface não está acessível$(NC)"
	@echo "$(GREEN)Teste concluído$(NC)"

# Limpeza completa (CUIDADO!)
clean:
	@echo "$(RED)ATENÇÃO: Isso irá remover TODOS os dados!$(NC)"
	@read -p "Tem certeza? Digite 'yes' para confirmar: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		docker compose down -v --remove-orphans; \
		docker volume prune -f; \
		docker image prune -f; \
		echo "$(GREEN)Limpeza concluída$(NC)"; \
	else \
		echo "$(YELLOW)Operação cancelada$(NC)"; \
	fi

# Backup do banco
backup:
	@echo "$(GREEN)Fazendo backup do banco de dados...$(NC)"
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	docker compose exec db mysqldump -u root -p$${MYSQL_ROOT_PASSWORD} zabbix > backup_zabbix_$$TIMESTAMP.sql; \
	echo "$(GREEN)Backup salvo como: backup_zabbix_$$TIMESTAMP.sql$(NC)"

# Restaurar backup
restore:
	@if [ -z "$(BACKUP)" ]; then \
		echo "$(RED)Erro: Especifique o arquivo de backup$(NC)"; \
		echo "Uso: make restore BACKUP=backup_arquivo.sql"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Restaurando backup: $(BACKUP)$(NC)"
	@docker compose exec -T db mysql -u root -p$${MYSQL_ROOT_PASSWORD} zabbix < $(BACKUP)
	@echo "$(GREEN)Backup restaurado com sucesso$(NC)"

# Comandos avançados
reset-admin-password:
	@echo "$(YELLOW)Configurando usuário Admin a partir do .env...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)Erro: Arquivo .env não encontrado!$(NC)"; \
		exit 1; \
	fi
	@eval $$(grep -v '^#' $(ENV_FILE) | xargs -d '\n'); \
	if [ -z "$$ZABBIX_WEB_USER" ] || [ -z "$$ZABBIX_WEB_PASSWORD" ]; then \
		echo "$(RED)Erro: ZABBIX_WEB_USER ou ZABBIX_WEB_PASSWORD não definidos no .env$(NC)"; \
		exit 1; \
	fi; \
	echo "$(YELLOW)Gerando hash bcrypt para senha: $$ZABBIX_WEB_PASSWORD$(NC)"; \
	HASH=$$(docker run --rm php:8.1-cli php -r "echo password_hash('$$ZABBIX_WEB_PASSWORD', PASSWORD_BCRYPT);"); \
	echo "$(YELLOW)Atualizando usuário: $$ZABBIX_WEB_USER$(NC)"; \
	docker compose exec db mysql -u root -prootpassword -e "UPDATE zabbix.users SET passwd = '$$HASH', attempt_failed = 0, attempt_clock = 0, attempt_ip = '' WHERE username = '$$ZABBIX_WEB_USER';" || \
	docker compose exec db mysql -u root -prootpassword -e "INSERT INTO zabbix.users (username, name, surname, passwd, autologin, autologout, lang, refresh, theme, attempt_failed, attempt_ip, attempt_clock, rows_per_page, timezone, roleid, userdirectoryid, ts_provisioned) VALUES ('$$ZABBIX_WEB_USER', 'Zabbix', 'Administrator', '$$HASH', 0, '15m', 'default', '30s', 'default', 0, '', 0, 50, 'default', 3, NULL, 0) ON DUPLICATE KEY UPDATE passwd = '$$HASH', attempt_failed = 0, attempt_clock = 0, attempt_ip = '';"; \
	echo "$(GREEN)Usuário configurado! Use: $$ZABBIX_WEB_USER / $$ZABBIX_WEB_PASSWORD$(NC)"

dev-logs:
	@echo "$(GREEN)Logs detalhados para desenvolvimento:$(NC)"
	docker compose logs -f --tail=100

dev-shell-db:
	@echo "$(GREEN)Acessando shell do MariaDB:$(NC)"
	docker compose exec db mysql -u root -p

dev-shell-server:
	@echo "$(GREEN)Acessando shell do Zabbix Server:$(NC)"
	docker compose exec zabbix-server sh

# Verificar se .env existe antes de comandos que precisam dele
check-env:
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)Erro: Arquivo .env não encontrado$(NC)"; \
		echo "Execute: make setup"; \
		exit 1; \
	fi

# Override para comandos que precisam do .env
up down restart backup restore: check-env