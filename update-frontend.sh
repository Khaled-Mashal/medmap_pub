#!/bin/bash

# سكريبت تحديث الواجهة الأمامية

echo "=========================================="
echo "  تحديث الواجهة الأمامية - MedMap"
echo "=========================================="
echo ""

# التحقق من وجود مجلد الفرونت إند
if [ ! -d "publish/wwwroot/build" ]; then
    echo "❌ مجلد publish/wwwroot/build غير موجود"
    exit 1
fi

# سؤال عن عنوان API
echo "📝 إعداد عنوان API:"
echo ""
echo "الخيارات المتاحة:"
echo "  1. استخدام النطاق: https://medmapgloble.com"
echo "  2. استخدام عنوان نسبي: /api (موصى به)"
echo "  3. إدخال عنوان مخصص"
echo ""
read -p "اختر [1/2/3] (الافتراضي: 2): " choice

case $choice in
    1)
        NEW_API_URL="https://medmapgloble.com"
        ;;
    3)
        read -p "أدخل عنوان API: " NEW_API_URL
        ;;
    *)
        NEW_API_URL=""
        echo "✅ سيتم استخدام عنوان نسبي (يعمل تلقائياً مع النطاق)"
        ;;
esac

echo ""
echo "🔄 جاري تحديث الواجهة الأمامية..."
echo ""

# إنشاء نسخة احتياطية
echo "1️⃣  إنشاء نسخة احتياطية..."
BACKUP_NAME="frontend_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
docker run --rm \
    -v medmap_frontend_data:/data \
    -v $(pwd)/backups:/backup \
    alpine tar czf /backup/$BACKUP_NAME -C /data . 2>/dev/null

if [ $? -eq 0 ]; then
    echo "   ✅ تم حفظ النسخة الاحتياطية: backups/$BACKUP_NAME"
else
    echo "   ⚠️  فشل إنشاء النسخة الاحتياطية (سيتم المتابعة)"
fi

# إنشاء مجلد مؤقت
TEMP_DIR=$(mktemp -d)
echo ""
echo "2️⃣  نسخ الملفات الجديدة..."
cp -r publish/wwwroot/build/* $TEMP_DIR/

# استبدال العناوين إذا لزم الأمر
if [ ! -z "$NEW_API_URL" ]; then
    echo ""
    echo "3️⃣  تحديث عناوين API..."
    
    # البحث عن جميع ملفات JavaScript
    find $TEMP_DIR -name "*.js" -type f | while read file; do
        # استبدال localhost:5000
        sed -i "s|http://localhost:5000|$NEW_API_URL|g" "$file" 2>/dev/null || \
        sed -i '' "s|http://localhost:5000|$NEW_API_URL|g" "$file" 2>/dev/null
        
        # استبدال localhost:5000 بدون http
        sed -i "s|localhost:5000|${NEW_API_URL#http://}|g" "$file" 2>/dev/null || \
        sed -i '' "s|localhost:5000|${NEW_API_URL#http://}|g" "$file" 2>/dev/null
    done
    
    echo "   ✅ تم تحديث عناوين API"
else
    echo ""
    echo "3️⃣  تحديث لاستخدام عناوين نسبية..."
    
    # استبدال بعناوين نسبية
    find $TEMP_DIR -name "*.js" -type f | while read file; do
        # استبدال http://localhost:5000/api بـ /api
        sed -i "s|http://localhost:5000/api|/api|g" "$file" 2>/dev/null || \
        sed -i '' "s|http://localhost:5000/api|/api|g" "$file" 2>/dev/null
        
        # استبدال http://localhost:5000 بـ ""
        sed -i "s|http://localhost:5000||g" "$file" 2>/dev/null || \
        sed -i '' "s|http://localhost:5000||g" "$file" 2>/dev/null
    done
    
    echo "   ✅ تم التحديث لاستخدام عناوين نسبية"
fi

# نسخ الملفات إلى الـ volume
echo ""
echo "4️⃣  نسخ الملفات إلى Docker volume..."
docker run --rm \
    -v medmap_frontend_data:/data \
    -v $TEMP_DIR:/source \
    alpine sh -c "rm -rf /data/* && cp -r /source/* /data/"

if [ $? -eq 0 ]; then
    echo "   ✅ تم نسخ الملفات بنجاح"
else
    echo "   ❌ فشل نسخ الملفات"
    rm -rf $TEMP_DIR
    exit 1
fi

# تنظيف المجلد المؤقت
rm -rf $TEMP_DIR

# إعادة تشغيل Nginx لتحديث الكاش
echo ""
echo "5️⃣  إعادة تشغيل Nginx..."
docker-compose restart nginx

if [ $? -eq 0 ]; then
    echo "   ✅ تم إعادة تشغيل Nginx"
else
    echo "   ⚠️  فشل إعادة تشغيل Nginx"
fi

# مسح الكاش من المتصفح
echo ""
echo "=========================================="
echo "✅ تم تحديث الواجهة الأمامية بنجاح!"
echo "=========================================="
echo ""
echo "📝 الخطوات التالية:"
echo "   1. امسح كاش المتصفح (Ctrl+Shift+Delete)"
echo "   2. أعد تحميل الصفحة (Ctrl+F5)"
echo "   3. تحقق من عنوان API في أدوات المطور (F12 > Network)"
echo ""
echo "🔍 للتحقق من الملفات:"
echo "   docker run --rm -v medmap_frontend_data:/data alpine ls -la /data"
echo ""
echo "♻️  للاستعادة من النسخة الاحتياطية:"
echo "   ./restore.sh frontend backups/$BACKUP_NAME"
echo ""

