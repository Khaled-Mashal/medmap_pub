#!/bin/bash

# سكريبت التحقق من الجاهزية قبل النشر

echo "=========================================="
echo "  فحص الجاهزية للنشر - MedMap"
echo "=========================================="
echo ""

ERRORS=0
WARNINGS=0

# دالة لطباعة النتائج
print_result() {
    local status=$1
    local message=$2
    
    if [ "$status" = "OK" ]; then
        echo "✅ $message"
    elif [ "$status" = "WARN" ]; then
        echo "⚠️  $message"
        ((WARNINGS++))
    else
        echo "❌ $message"
        ((ERRORS++))
    fi
}

# 1. فحص Docker
echo "1️⃣  فحص Docker..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    print_result "OK" "Docker مثبت (الإصدار: $DOCKER_VERSION)"
else
    print_result "ERROR" "Docker غير مثبت"
fi

# 2. فحص Docker Compose
echo ""
echo "2️⃣  فحص Docker Compose..."
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version | awk '{print $4}' | sed 's/,//')
    print_result "OK" "Docker Compose مثبت (الإصدار: $COMPOSE_VERSION)"
else
    print_result "ERROR" "Docker Compose غير مثبت"
fi

# 3. فحص ملف .env
echo ""
echo "3️⃣  فحص ملف .env..."
if [ -f .env ]; then
    print_result "OK" "ملف .env موجود"
    
    # فحص كلمة المرور
    if grep -q "POSTGRES_PASSWORD=admin" .env; then
        print_result "WARN" "كلمة مرور قاعدة البيانات الافتراضية (يُنصح بتغييرها)"
    else
        print_result "OK" "كلمة مرور قاعدة البيانات مخصصة"
    fi
else
    print_result "ERROR" "ملف .env غير موجود"
fi

# 4. فحص مجلد publish
echo ""
echo "4️⃣  فحص مجلد publish..."
if [ -d "publish" ]; then
    print_result "OK" "مجلد publish موجود"
    
    # فحص الملف التنفيذي
    if [ -f "publish/medicalservices_api" ]; then
        print_result "OK" "الملف التنفيذي موجود"
    else
        print_result "ERROR" "الملف التنفيذي غير موجود"
    fi
    
    # فحص appsettings.json
    if [ -f "publish/appsettings.json" ]; then
        print_result "OK" "ملف appsettings.json موجود"
        
        # فحص اتصال قاعدة البيانات
        if grep -q "Host=postgres" publish/appsettings.json; then
            print_result "OK" "اتصال قاعدة البيانات مُعد لـ Docker"
        else
            print_result "WARN" "اتصال قاعدة البيانات قد يحتاج تعديل"
        fi
    else
        print_result "ERROR" "ملف appsettings.json غير موجود"
    fi
else
    print_result "ERROR" "مجلد publish غير موجود"
fi

# 5. فحص Dockerfile
echo ""
echo "5️⃣  فحص Dockerfile..."
if [ -f "publish/Dockerfile" ]; then
    print_result "OK" "Dockerfile موجود"
else
    print_result "ERROR" "Dockerfile غير موجود"
fi

# 6. فحص docker-compose.yml
echo ""
echo "6️⃣  فحص docker-compose.yml..."
if [ -f "docker-compose.yml" ]; then
    print_result "OK" "docker-compose.yml موجود"
else
    print_result "ERROR" "docker-compose.yml غير موجود"
fi

# 7. فحص إعدادات Nginx
echo ""
echo "7️⃣  فحص إعدادات Nginx..."
if [ -f "nginx/nginx.conf" ]; then
    print_result "OK" "nginx.conf موجود"
else
    print_result "ERROR" "nginx.conf غير موجود"
fi

if [ -f "nginx/conf.d/medmap.conf" ]; then
    print_result "OK" "medmap.conf موجود"
else
    print_result "ERROR" "medmap.conf غير موجود"
fi

# 8. فحص المجلدات المطلوبة
echo ""
echo "8️⃣  فحص المجلدات..."
for dir in "nginx/ssl" "nginx/conf.d" "backups"; do
    if [ -d "$dir" ]; then
        print_result "OK" "مجلد $dir موجود"
    else
        print_result "WARN" "مجلد $dir غير موجود (سيتم إنشاؤه)"
        mkdir -p "$dir"
    fi
done

# 9. فحص صلاحيات السكريبتات
echo ""
echo "9️⃣  فحص صلاحيات السكريبتات..."
SCRIPTS=("start.sh" "stop.sh" "backup.sh" "logs.sh" "health-check.sh")
for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            print_result "OK" "$script قابل للتنفيذ"
        else
            print_result "WARN" "$script غير قابل للتنفيذ (سيتم إصلاحه)"
            chmod +x "$script"
        fi
    else
        print_result "WARN" "$script غير موجود"
    fi
done

# 10. فحص المنافذ
echo ""
echo "🔟 فحص المنافذ..."
PORTS=(80 443 5000 5432)
for port in "${PORTS[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_result "WARN" "المنفذ $port مستخدم (قد يسبب تعارض)"
    else
        print_result "OK" "المنفذ $port متاح"
    fi
done

# 11. فحص مساحة التخزين
echo ""
echo "1️⃣1️⃣  فحص مساحة التخزين..."
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
DISK_AVAIL=$(df -h / | tail -1 | awk '{print $4}')

if [ $DISK_USAGE -lt 80 ]; then
    print_result "OK" "مساحة التخزين كافية (متاح: $DISK_AVAIL)"
else
    print_result "WARN" "مساحة التخزين منخفضة (متاح: $DISK_AVAIL)"
fi

# 12. فحص الذاكرة
echo ""
echo "1️⃣2️⃣  فحص الذاكرة..."
TOTAL_MEM=$(free -h | awk '/^Mem:/ {print $2}')
AVAIL_MEM=$(free -h | awk '/^Mem:/ {print $7}')

print_result "OK" "الذاكرة الكلية: $TOTAL_MEM (متاح: $AVAIL_MEM)"

# 13. فحص الاتصال بالإنترنت
echo ""
echo "1️⃣3️⃣  فحص الاتصال بالإنترنت..."
if ping -c 1 8.8.8.8 &> /dev/null; then
    print_result "OK" "الاتصال بالإنترنت متاح"
else
    print_result "WARN" "لا يوجد اتصال بالإنترنت"
fi

# النتيجة النهائية
echo ""
echo "=========================================="
echo "  النتيجة النهائية"
echo "=========================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "🎉 ممتاز! النظام جاهز للنشر"
    echo ""
    echo "الخطوات التالية:"
    echo "  1. تشغيل التطبيق: make start أو ./start.sh"
    echo "  2. التحقق من الصحة: make health أو ./health-check.sh"
    echo "  3. إعداد SSL: make ssl أو ./setup-ssl.sh"
    echo "  4. إعداد الجدار الناري: sudo ./setup-firewall.sh"
    echo "  5. إعداد التنبيهات: ./alert-setup.sh"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  يوجد $WARNINGS تحذير"
    echo "يمكنك المتابعة ولكن يُنصح بمعالجة التحذيرات"
    echo ""
    read -p "هل تريد المتابعة؟ (y/n): " continue
    if [ "$continue" = "y" ]; then
        exit 0
    else
        exit 1
    fi
else
    echo "❌ يوجد $ERRORS خطأ و $WARNINGS تحذير"
    echo "يجب إصلاح الأخطاء قبل النشر"
    exit 1
fi

