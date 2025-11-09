#!/bin/bash

# سكريبت فحص صحة النظام

echo "=========================================="
echo "  فحص صحة MedMap"
echo "=========================================="
echo ""

# فحص حالة الحاويات
echo "📊 حالة الحاويات:"
docker-compose ps
echo ""

# فحص استهلاك الموارد
echo "💻 استهلاك الموارد:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
echo ""

# فحص مساحة التخزين
echo "💾 مساحة التخزين:"
docker system df
echo ""

# فحص Volumes
echo "📦 حجم البيانات المحفوظة:"
docker volume ls --format "table {{.Name}}\t{{.Driver}}" | grep medmap
echo ""

# فحص الاتصال بـ API
echo "🌐 فحص الاتصال بـ API:"
if curl -f -s http://localhost:5000 > /dev/null; then
    echo "✅ API يعمل بشكل صحيح"
else
    echo "❌ API لا يستجيب"
fi
echo ""

# فحص الاتصال بـ Nginx
echo "🌐 فحص الاتصال بـ Nginx:"
if curl -f -s http://localhost > /dev/null; then
    echo "✅ Nginx يعمل بشكل صحيح"
else
    echo "❌ Nginx لا يستجيب"
fi
echo ""

# فحص قاعدة البيانات
echo "🗄️  فحص قاعدة البيانات:"
if docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
    echo "✅ PostgreSQL يعمل بشكل صحيح"
    
    # عرض حجم قاعدة البيانات
    DB_SIZE=$(docker-compose exec -T postgres psql -U postgres -d medical_services_db -t -c "SELECT pg_size_pretty(pg_database_size('medical_services_db'));" 2>/dev/null | xargs)
    echo "   حجم قاعدة البيانات: $DB_SIZE"
else
    echo "❌ PostgreSQL لا يعمل"
fi
echo ""

# فحص السجلات للأخطاء
echo "⚠️  الأخطاء الأخيرة:"
ERROR_COUNT=$(docker-compose logs --tail=100 | grep -i "error\|exception\|fatal" | wc -l)
if [ $ERROR_COUNT -eq 0 ]; then
    echo "✅ لا توجد أخطاء في السجلات الأخيرة"
else
    echo "⚠️  وجد $ERROR_COUNT خطأ في السجلات الأخيرة"
    echo "   استخدم: ./logs.sh لعرض التفاصيل"
fi
echo ""

echo "=========================================="
echo "✅ اكتمل الفحص"
echo "=========================================="

