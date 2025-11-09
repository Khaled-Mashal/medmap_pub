#!/bin/bash

# سكريبت إصلاح صلاحيات الملفات

echo "=========================================="
echo "  إصلاح صلاحيات الملفات"
echo "=========================================="
echo ""

# قائمة جميع السكريبتات
SCRIPTS=(
    "start.sh"
    "stop.sh"
    "restart.sh"
    "logs.sh"
    "backup.sh"
    "restore.sh"
    "health-check.sh"
    "monitor.sh"
    "update.sh"
    "update-frontend.sh"
    "setup-ssl.sh"
    "setup-firewall.sh"
    "alert-setup.sh"
    "auto-backup-setup.sh"
    "pre-deploy-check.sh"
    "db-manage.sh"
    "fix-permissions.sh"
)

echo "🔧 إعطاء صلاحيات التنفيذ للسكريبتات..."
echo ""

SUCCESS=0
FAILED=0

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        if [ $? -eq 0 ]; then
            echo "✅ $script"
            ((SUCCESS++))
        else
            echo "❌ $script (فشل)"
            ((FAILED++))
        fi
    else
        echo "⚠️  $script (غير موجود)"
    fi
done

echo ""
echo "=========================================="
echo "📊 النتيجة:"
echo "   ✅ نجح: $SUCCESS"
echo "   ❌ فشل: $FAILED"
echo "=========================================="
echo ""

if [ $FAILED -eq 0 ]; then
    echo "✅ تم إصلاح جميع الصلاحيات بنجاح!"
    exit 0
else
    echo "⚠️  بعض الملفات فشلت"
    exit 1
fi

