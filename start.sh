#!/bin/bash

# سكريبت تشغيل MedMap

echo "=========================================="
echo "  بدء تشغيل MedMap"
echo "=========================================="

# التحقق من وجود Docker
if ! command -v docker &> /dev/null; then
    echo "❌ خطأ: Docker غير مثبت"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ خطأ: Docker Compose غير مثبت"
    exit 1
fi

# التحقق من وجود ملف .env
if [ ! -f .env ]; then
    echo "⚠️  تحذير: ملف .env غير موجود"
    echo "📝 إنشاء ملف .env من .env.example..."
    cp .env.example .env
    echo "✅ تم إنشاء ملف .env - يرجى تعديله قبل المتابعة"
    echo "   nano .env"
    exit 0
fi

# إنشاء المجلدات المطلوبة
echo "📁 إنشاء المجلدات المطلوبة..."
mkdir -p nginx/ssl
mkdir -p nginx/conf.d
mkdir -p publish/wwwroot/uploads

# بناء وتشغيل الحاويات
echo "🔨 بناء الصور..."
docker-compose build

echo "🚀 تشغيل الخدمات..."
docker-compose up -d

# الانتظار قليلاً
echo "⏳ انتظار بدء الخدمات..."
sleep 5

# التحقق من حالة الخدمات
echo ""
echo "📊 حالة الخدمات:"
docker-compose ps

echo ""
echo "=========================================="
echo "✅ تم تشغيل MedMap بنجاح!"
echo "=========================================="
echo ""
echo "🌐 الروابط:"
echo "   - التطبيق: http://localhost"
echo "   - API مباشر: http://localhost:5000"
echo ""
echo "📝 أوامر مفيدة:"
echo "   - عرض السجلات: docker-compose logs -f"
echo "   - إيقاف الخدمات: docker-compose down"
echo "   - إعادة التشغيل: docker-compose restart"
echo ""

