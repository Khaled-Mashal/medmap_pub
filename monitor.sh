#!/bin/bash

# سكريبت مراقبة الأداء المستمر

echo "=========================================="
echo "  مراقبة أداء MedMap"
echo "=========================================="
echo ""
echo "اضغط Ctrl+C للخروج"
echo ""

# دالة لعرض معلومات الأداء
show_stats() {
    clear
    echo "=========================================="
    echo "  مراقبة MedMap - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=========================================="
    echo ""
    
    # حالة الحاويات
    echo "📊 حالة الحاويات:"
    docker-compose ps
    echo ""
    
    # استهلاك الموارد
    echo "💻 استهلاك الموارد:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
    echo ""
    
    # حجم قاعدة البيانات
    echo "🗄️  قاعدة البيانات:"
    DB_SIZE=$(docker-compose exec -T postgres psql -U postgres -d medical_services_db -t -c "SELECT pg_size_pretty(pg_database_size('medical_services_db'));" 2>/dev/null | xargs)
    DB_CONNECTIONS=$(docker-compose exec -T postgres psql -U postgres -t -c "SELECT count(*) FROM pg_stat_activity WHERE datname='medical_services_db';" 2>/dev/null | xargs)
    echo "   حجم البيانات: $DB_SIZE"
    echo "   الاتصالات النشطة: $DB_CONNECTIONS"
    echo ""
    
    # مساحة التخزين
    echo "💾 مساحة التخزين:"
    df -h / | tail -1 | awk '{print "   المستخدم: "$3" / "$2" ("$5")"}'
    echo ""
    
    # الأخطاء الأخيرة
    echo "⚠️  الأخطاء في آخر دقيقة:"
    ERROR_COUNT=$(docker-compose logs --since 1m 2>/dev/null | grep -i "error\|exception\|fatal" | wc -l)
    if [ $ERROR_COUNT -eq 0 ]; then
        echo "   ✅ لا توجد أخطاء"
    else
        echo "   ⚠️  $ERROR_COUNT خطأ"
    fi
    echo ""
    
    # الطلبات (من سجلات Nginx)
    echo "🌐 الطلبات في آخر دقيقة:"
    REQUEST_COUNT=$(docker-compose logs nginx --since 1m 2>/dev/null | grep -c "GET\|POST\|PUT\|DELETE" || echo "0")
    echo "   عدد الطلبات: $REQUEST_COUNT"
    echo ""
    
    echo "=========================================="
    echo "التحديث التالي بعد 5 ثوانٍ..."
}

# حلقة المراقبة
while true; do
    show_stats
    sleep 5
done

