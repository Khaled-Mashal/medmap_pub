#!/bin/bash

# سكريبت إعداد النسخ الاحتياطي التلقائي

echo "=========================================="
echo "  إعداد النسخ الاحتياطي التلقائي"
echo "=========================================="
echo ""

# الإعدادات الافتراضية
BACKUP_DIR="$(pwd)/backups"
BACKUP_RETENTION_DAYS=30
BACKUP_TIME="02:00"  # 2 صباحاً

echo "📋 الإعدادات الحالية:"
echo "   مجلد النسخ الاحتياطية: $BACKUP_DIR"
echo "   مدة الاحتفاظ: $BACKUP_RETENTION_DAYS يوم"
echo "   وقت النسخ الاحتياطي: $BACKUP_TIME"
echo ""

read -p "هل تريد تغيير الإعدادات؟ (y/n): " change_settings

if [ "$change_settings" = "y" ]; then
    read -p "مجلد النسخ الاحتياطية [$BACKUP_DIR]: " input_dir
    if [ ! -z "$input_dir" ]; then
        BACKUP_DIR=$input_dir
    fi
    
    read -p "مدة الاحتفاظ بالنسخ (أيام) [$BACKUP_RETENTION_DAYS]: " input_retention
    if [ ! -z "$input_retention" ]; then
        BACKUP_RETENTION_DAYS=$input_retention
    fi
    
    read -p "وقت النسخ الاحتياطي (HH:MM) [$BACKUP_TIME]: " input_time
    if [ ! -z "$input_time" ]; then
        BACKUP_TIME=$input_time
    fi
fi

# إنشاء مجلد النسخ الاحتياطية
mkdir -p "$BACKUP_DIR"

# إنشاء سكريبت النسخ الاحتياطي التلقائي
BACKUP_SCRIPT="/usr/local/bin/medmap-auto-backup.sh"

echo "📝 إنشاء سكريبت النسخ الاحتياطي..."
sudo tee $BACKUP_SCRIPT > /dev/null << EOF
#!/bin/bash

# سكريبت النسخ الاحتياطي التلقائي لـ MedMap

PROJECT_DIR="$(pwd)"
BACKUP_DIR="$BACKUP_DIR"
RETENTION_DAYS=$BACKUP_RETENTION_DAYS
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
LOG_FILE="\$BACKUP_DIR/backup.log"

cd \$PROJECT_DIR

echo "=========================================" >> \$LOG_FILE
echo "[\$(date)] بدء النسخ الاحتياطي التلقائي" >> \$LOG_FILE
echo "=========================================" >> \$LOG_FILE

# نسخ احتياطي لقاعدة البيانات
echo "[\$(date)] نسخ احتياطي لقاعدة البيانات..." >> \$LOG_FILE
docker-compose exec -T postgres pg_dump -U postgres medical_services_db > "\$BACKUP_DIR/database_\$TIMESTAMP.sql" 2>> \$LOG_FILE

if [ \$? -eq 0 ]; then
    echo "[\$(date)] ✅ تم حفظ قاعدة البيانات" >> \$LOG_FILE
    gzip "\$BACKUP_DIR/database_\$TIMESTAMP.sql"
else
    echo "[\$(date)] ❌ فشل النسخ الاحتياطي لقاعدة البيانات" >> \$LOG_FILE
fi

# نسخ احتياطي للملفات المرفوعة
echo "[\$(date)] نسخ احتياطي للملفات المرفوعة..." >> \$LOG_FILE
docker run --rm \
    -v medmap_uploads_data:/data \
    -v \$BACKUP_DIR:/backup \
    alpine tar czf /backup/uploads_\$TIMESTAMP.tar.gz -C /data . 2>> \$LOG_FILE

if [ \$? -eq 0 ]; then
    echo "[\$(date)] ✅ تم حفظ الملفات المرفوعة" >> \$LOG_FILE
else
    echo "[\$(date)] ❌ فشل النسخ الاحتياطي للملفات المرفوعة" >> \$LOG_FILE
fi

# نسخ احتياطي للواجهة الأمامية
echo "[\$(date)] نسخ احتياطي للواجهة الأمامية..." >> \$LOG_FILE
docker run --rm \
    -v medmap_frontend_data:/data \
    -v \$BACKUP_DIR:/backup \
    alpine tar czf /backup/frontend_\$TIMESTAMP.tar.gz -C /data . 2>> \$LOG_FILE

if [ \$? -eq 0 ]; then
    echo "[\$(date)] ✅ تم حفظ الواجهة الأمامية" >> \$LOG_FILE
else
    echo "[\$(date)] ❌ فشل النسخ الاحتياطي للواجهة الأمامية" >> \$LOG_FILE
fi

# حذف النسخ القديمة
echo "[\$(date)] حذف النسخ الاحتياطية الأقدم من \$RETENTION_DAYS يوم..." >> \$LOG_FILE
find \$BACKUP_DIR -name "database_*.sql.gz" -mtime +\$RETENTION_DAYS -delete 2>> \$LOG_FILE
find \$BACKUP_DIR -name "uploads_*.tar.gz" -mtime +\$RETENTION_DAYS -delete 2>> \$LOG_FILE
find \$BACKUP_DIR -name "frontend_*.tar.gz" -mtime +\$RETENTION_DAYS -delete 2>> \$LOG_FILE

# حساب حجم النسخ الاحتياطية
BACKUP_SIZE=\$(du -sh \$BACKUP_DIR | awk '{print \$1}')
BACKUP_COUNT=\$(ls -1 \$BACKUP_DIR/*.gz 2>/dev/null | wc -l)

echo "[\$(date)] حجم النسخ الاحتياطية: \$BACKUP_SIZE" >> \$LOG_FILE
echo "[\$(date)] عدد النسخ الاحتياطية: \$BACKUP_COUNT" >> \$LOG_FILE
echo "[\$(date)] ✅ اكتمل النسخ الاحتياطي التلقائي" >> \$LOG_FILE
echo "" >> \$LOG_FILE
EOF

# إعطاء صلاحيات التنفيذ
sudo chmod +x $BACKUP_SCRIPT

# تحويل الوقت إلى صيغة Cron
HOUR=$(echo $BACKUP_TIME | cut -d: -f1)
MINUTE=$(echo $BACKUP_TIME | cut -d: -f2)

# إضافة إلى Cron
echo "⏰ إضافة إلى Cron..."
(crontab -l 2>/dev/null | grep -v "medmap-auto-backup.sh"; echo "$MINUTE $HOUR * * * $BACKUP_SCRIPT") | crontab -

# اختبار النسخ الاحتياطي
echo ""
read -p "هل تريد اختبار النسخ الاحتياطي الآن؟ (y/n): " test_backup

if [ "$test_backup" = "y" ]; then
    echo "🧪 اختبار النسخ الاحتياطي..."
    sudo $BACKUP_SCRIPT
    
    echo ""
    echo "📊 النسخ الاحتياطية المتاحة:"
    ls -lh "$BACKUP_DIR"/*.gz 2>/dev/null || echo "لا توجد نسخ احتياطية بعد"
fi

echo ""
echo "=========================================="
echo "✅ تم إعداد النسخ الاحتياطي التلقائي!"
echo "=========================================="
echo ""
echo "📋 الإعدادات:"
echo "   📁 المجلد: $BACKUP_DIR"
echo "   ⏰ الوقت: $BACKUP_TIME يومياً"
echo "   🗓️  الاحتفاظ: $BACKUP_RETENTION_DAYS يوم"
echo "   📝 السجل: $BACKUP_DIR/backup.log"
echo ""
echo "📊 ما يتم نسخه احتياطياً:"
echo "   ✅ قاعدة البيانات (مضغوطة)"
echo "   ✅ الملفات المرفوعة"
echo "   ✅ الواجهة الأمامية"
echo ""
echo "🔧 الإدارة:"
echo "   - تشغيل يدوي: sudo $BACKUP_SCRIPT"
echo "   - عرض السجل: cat $BACKUP_DIR/backup.log"
echo "   - عرض النسخ: ls -lh $BACKUP_DIR/"
echo "   - تعديل الإعدادات: crontab -e"
echo ""
echo "⚠️  ملاحظة: تأكد من وجود مساحة كافية في $BACKUP_DIR"
echo ""

