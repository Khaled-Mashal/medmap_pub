.PHONY: help start stop restart logs health backup restore update ssl clean dev

# الألوان للطباعة
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m # No Color

help: ## عرض هذه المساعدة
	@echo "$(GREEN)=========================================="
	@echo "  أوامر MedMap المتاحة"
	@echo "==========================================$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

start: ## تشغيل التطبيق
	@echo "$(GREEN)🚀 تشغيل MedMap...$(NC)"
	@chmod +x start.sh
	@./start.sh

stop: ## إيقاف التطبيق
	@echo "$(RED)🛑 إيقاف MedMap...$(NC)"
	@chmod +x stop.sh
	@./stop.sh

restart: ## إعادة تشغيل التطبيق
	@echo "$(YELLOW)🔄 إعادة تشغيل MedMap...$(NC)"
	@docker-compose restart

logs: ## عرض السجلات
	@chmod +x logs.sh
	@./logs.sh

health: ## فحص صحة النظام
	@chmod +x health-check.sh
	@./health-check.sh

backup: ## عمل نسخة احتياطية
	@echo "$(GREEN)💾 عمل نسخة احتياطية...$(NC)"
	@chmod +x backup.sh
	@./backup.sh

restore: ## استعادة من نسخة احتياطية
	@echo "$(YELLOW)🔄 استعادة البيانات...$(NC)"
	@chmod +x db-manage.sh
	@./db-manage.sh

update: ## تحديث التطبيق
	@echo "$(GREEN)⬆️  تحديث التطبيق...$(NC)"
	@chmod +x update.sh
	@./update.sh

ssl: ## إعداد SSL
	@echo "$(GREEN)🔐 إعداد SSL...$(NC)"
	@chmod +x setup-ssl.sh
	@./setup-ssl.sh

clean: ## تنظيف الملفات المؤقتة
	@echo "$(YELLOW)🧹 تنظيف...$(NC)"
	@docker system prune -f
	@echo "$(GREEN)✅ تم التنظيف$(NC)"

dev: ## تشغيل بيئة التطوير
	@echo "$(GREEN)🔧 تشغيل بيئة التطوير...$(NC)"
	@docker-compose -f docker-compose.dev.yml up -d
	@echo "$(GREEN)✅ بيئة التطوير جاهزة$(NC)"
	@echo "$(YELLOW)PostgreSQL: localhost:5432$(NC)"
	@echo "$(YELLOW)pgAdmin: http://localhost:5050$(NC)"

dev-stop: ## إيقاف بيئة التطوير
	@echo "$(RED)🛑 إيقاف بيئة التطوير...$(NC)"
	@docker-compose -f docker-compose.dev.yml down

ps: ## عرض حالة الحاويات
	@docker-compose ps

stats: ## عرض استهلاك الموارد
	@docker stats --no-stream

db: ## إدارة قاعدة البيانات
	@chmod +x db-manage.sh
	@./db-manage.sh

build: ## بناء الصور
	@echo "$(GREEN)🔨 بناء الصور...$(NC)"
	@docker-compose build

up: ## تشغيل الخدمات
	@docker-compose up -d

down: ## إيقاف وحذف الحاويات
	@docker-compose down

down-all: ## إيقاف وحذف كل شيء (بما في ذلك البيانات)
	@echo "$(RED)⚠️  تحذير: سيتم حذف جميع البيانات!$(NC)"
	@read -p "اكتب 'yes' للتأكيد: " confirm && [ "$$confirm" = "yes" ] && docker-compose down -v || echo "تم الإلغاء"

install-docker: ## تثبيت Docker و Docker Compose
	@echo "$(GREEN)📦 تثبيت Docker...$(NC)"
	@curl -fsSL https://get.docker.com -o get-docker.sh
	@sudo sh get-docker.sh
	@sudo apt-get install -y docker-compose-plugin
	@sudo usermod -aG docker $$USER
	@echo "$(GREEN)✅ تم تثبيت Docker$(NC)"
	@echo "$(YELLOW)⚠️  يرجى تسجيل الخروج والدخول مرة أخرى$(NC)"

setup: ## إعداد أولي للمشروع
	@echo "$(GREEN)⚙️  إعداد المشروع...$(NC)"
	@cp .env.example .env
	@mkdir -p nginx/ssl nginx/conf.d backups
	@chmod +x *.sh
	@echo "$(GREEN)✅ تم الإعداد$(NC)"
	@echo "$(YELLOW)📝 يرجى تعديل ملف .env قبل التشغيل$(NC)"

