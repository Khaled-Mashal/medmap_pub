#!/bin/bash

# سكريبت إدارة قاعدة البيانات

echo "=========================================="
echo "  إدارة قاعدة البيانات - MedMap"
echo "=========================================="
echo ""
echo "اختر العملية:"
echo "  1) الدخول إلى قاعدة البيانات (psql)"
echo "  2) نسخ احتياطي لقاعدة البيانات"
echo "  3) استعادة من نسخة احتياطية"
echo "  4) عرض حجم قاعدة البيانات"
echo "  5) عرض الجداول"
echo "  6) تنظيف قاعدة البيانات (VACUUM)"
echo "  7) إعادة تعيين قاعدة البيانات (حذف جميع البيانات)"
echo "  0) خروج"
echo ""
read -p "الاختيار [0-7]: " choice

case $choice in
    1)
        echo "🔌 الاتصال بقاعدة البيانات..."
        docker-compose exec postgres psql -U postgres -d medical_services_db
        ;;
    
    2)
        BACKUP_FILE="backups/database_$(date +%Y%m%d_%H%M%S).sql"
        mkdir -p backups
        echo "💾 إنشاء نسخة احتياطية..."
        docker-compose exec -T postgres pg_dump -U postgres medical_services_db > "$BACKUP_FILE"
        if [ $? -eq 0 ]; then
            echo "✅ تم حفظ النسخة الاحتياطية: $BACKUP_FILE"
            ls -lh "$BACKUP_FILE"
        else
            echo "❌ فشل النسخ الاحتياطي"
        fi
        ;;
    
    3)
        echo "📂 الملفات المتاحة:"
        ls -lh backups/*.sql 2>/dev/null
        echo ""
        read -p "أدخل اسم الملف (مثال: backups/database_20240101_120000.sql): " backup_file
        
        if [ ! -f "$backup_file" ]; then
            echo "❌ الملف غير موجود"
            exit 1
        fi
        
        echo "⚠️  تحذير: سيتم حذف جميع البيانات الحالية!"
        read -p "هل أنت متأكد؟ (yes/no): " confirm
        
        if [ "$confirm" = "yes" ]; then
            
            echo "🗑️  حذف جميع الجداول القديمة..."
            docker-compose exec -T postgres psql -U postgres -d medical_services_db <<EOF
DO \$\$
DECLARE
    r RECORD;
BEGIN
    -- تعطيل القيود الأجنبية
    EXECUTE 'SET session_replication_role = replica';

    -- حذف كل الجداول في schema public
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = ''public'') LOOP
        EXECUTE 'DROP TABLE IF EXISTS public.' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;

    -- إعادة تفعيل القيود
    EXECUTE 'SET session_replication_role = DEFAULT';
END
\$\$;
EOF

            echo "🔄 استعادة البيانات..."
            docker-compose exec -T postgres psql -U postgres medical_services_db < "$backup_file"

            if [ $? -eq 0 ]; then
                echo "✅ تمت الاستعادة بنجاح بدون أخطاء"
            else
                echo "❌ فشلت الاستعادة"
            fi
        else
            echo "❌ تم الإلغاء"
        fi
        ;;
    
    4)
        echo "📊 حجم قاعدة البيانات:"
        docker-compose exec postgres psql -U postgres -d medical_services_db -c "
            SELECT 
                pg_size_pretty(pg_database_size('medical_services_db')) as database_size,
                pg_size_pretty(pg_total_relation_size('public.*')) as tables_size;
        "
        ;;
    
    5)
        echo "📋 الجداول في قاعدة البيانات:"
        docker-compose exec postgres psql -U postgres -d medical_services_db -c "
            SELECT 
                schemaname,
                tablename,
                pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
            FROM pg_tables 
            WHERE schemaname = 'public'
            ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
        "
        ;;
    
    6)
        echo "🧹 تنظيف قاعدة البيانات..."
        docker-compose exec postgres psql -U postgres -d medical_services_db -c "VACUUM ANALYZE;"
        if [ $? -eq 0 ]; then
            echo "✅ تم التنظيف بنجاح"
        else
            echo "❌ فشل التنظيف"
        fi
        ;;
    
    7)
        echo "⚠️⚠️⚠️  تحذير خطير! ⚠️⚠️⚠️"
        echo "سيتم حذف جميع البيانات في قاعدة البيانات!"
        echo ""
        read -p "اكتب 'DELETE ALL DATA' للتأكيد: " confirm
        
        if [ "$confirm" = "DELETE ALL DATA" ]; then
            echo "💾 عمل نسخة احتياطية أولاً..."
            BACKUP_FILE="backups/before_reset_$(date +%Y%m%d_%H%M%S).sql"
            mkdir -p backups
            docker-compose exec -T postgres pg_dump -U postgres medical_services_db > "$BACKUP_FILE"
            
            echo "🗑️  حذف قاعدة البيانات..."
            docker-compose exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS medical_services_db;"
            docker-compose exec postgres psql -U postgres -c "CREATE DATABASE medical_services_db;"
            
            echo "✅ تم إعادة تعيين قاعدة البيانات"
            echo "📝 تم حفظ نسخة احتياطية في: $BACKUP_FILE"
            echo "⚠️  ستحتاج إلى إعادة تشغيل التطبيق لإنشاء الجداول"
        else
            echo "❌ تم الإلغاء"
        fi
        ;;
    
    0)
        echo "👋 إلى اللقاء"
        exit 0
        ;;
    
    *)
        echo "❌ اختيار غير صحيح"
        exit 1
        ;;
esac

echo ""
