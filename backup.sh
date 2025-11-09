#!/bin/bash

# سكريبت النسخ الاحتياطي لـ MedMap

BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=========================================="
echo "  نسخ احتياطي لـ MedMap"
echo "=========================================="

# إنشاء مجلد النسخ الاحتياطية
mkdir -p $BACKUP_DIR

# نسخ احتياطي لقاعدة البيانات
echo "💾 نسخ احتياطي لقاعدة البيانات..."
docker-compose exec -T postgres pg_dump -U postgres medical_services_db > "$BACKUP_DIR/database_$TIMESTAMP.sql"

if [ $? -eq 0 ]; then
    echo "✅ تم حفظ قاعدة البيانات: $BACKUP_DIR/database_$TIMESTAMP.sql"
else
    echo "❌ فشل النسخ الاحتياطي لقاعدة البيانات"
fi

# نسخ احتياطي للملفات المرفوعة
echo "📁 نسخ احتياطي للملفات المرفوعة..."
docker run --rm \
    -v medmap_uploads_data:/data \
    -v $(pwd)/$BACKUP_DIR:/backup \
    alpine tar czf /backup/uploads_$TIMESTAMP.tar.gz -C /data .

if [ $? -eq 0 ]; then
    echo "✅ تم حفظ الملفات المرفوعة: $BACKUP_DIR/uploads_$TIMESTAMP.tar.gz"
else
    echo "❌ فشل النسخ الاحتياطي للملفات المرفوعة"
fi

# نسخ احتياطي لملفات الواجهة الأمامية
echo "🎨 نسخ احتياطي للواجهة الأمامية..."
docker run --rm \
    -v medmap_frontend_data:/data \
    -v $(pwd)/$BACKUP_DIR:/backup \
    alpine tar czf /backup/frontend_$TIMESTAMP.tar.gz -C /data .

if [ $? -eq 0 ]; then
    echo "✅ تم حفظ الواجهة الأمامية: $BACKUP_DIR/frontend_$TIMESTAMP.tar.gz"
else
    echo "❌ فشل النسخ الاحتياطي للواجهة الأمامية"
fi

echo ""
echo "=========================================="
echo "✅ اكتمل النسخ الاحتياطي!"
echo "=========================================="
echo ""
echo "📂 الملفات المحفوظة في: $BACKUP_DIR/"
ls -lh $BACKUP_DIR/*$TIMESTAMP*
echo ""

