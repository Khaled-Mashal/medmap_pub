#!/bin/bash

# سكريبت للتحقق من الخطوط في Docker

echo "=========================================="
echo "  🔍 التحقق من الخطوط في Docker"
echo "=========================================="
echo ""

# التحقق من تشغيل الحاوية
if ! docker ps | grep -q medmap_api; then
    echo "❌ خطأ: حاوية medmap_api غير قيد التشغيل"
    echo ""
    echo "قم بتشغيلها أولاً:"
    echo "  docker-compose up -d api"
    exit 1
fi

echo "✅ حاوية medmap_api قيد التشغيل"
echo ""

# 1. التحقق من مجلد Fonts في التطبيق
echo "=========================================="
echo "1️⃣  التحقق من مجلد /app/Fonts"
echo "=========================================="
echo ""

if docker exec medmap_api test -d /app/Fonts; then
    echo "✅ مجلد /app/Fonts موجود"
    echo ""
    echo "📁 محتويات المجلد:"
    docker exec medmap_api ls -lh /app/Fonts/ | head -15
    echo ""
    
    # عد الخطوط
    FONT_COUNT=$(docker exec medmap_api sh -c "ls /app/Fonts/*.TTF /app/Fonts/*.ttf 2>/dev/null | wc -l")
    echo "📊 عدد الخطوط: $FONT_COUNT"
else
    echo "❌ مجلد /app/Fonts غير موجود!"
fi

echo ""

# 2. التحقق من مجلد الخطوط في النظام
echo "=========================================="
echo "2️⃣  التحقق من مجلد النظام"
echo "=========================================="
echo ""

if docker exec medmap_api test -d /usr/share/fonts/truetype/app-fonts; then
    echo "✅ مجلد /usr/share/fonts/truetype/app-fonts موجود"
    echo ""
    echo "📁 محتويات المجلد:"
    docker exec medmap_api ls -lh /usr/share/fonts/truetype/app-fonts/ | head -15
    echo ""
    
    # عد الخطوط
    SYSTEM_FONT_COUNT=$(docker exec medmap_api sh -c "ls /usr/share/fonts/truetype/app-fonts/*.TTF /usr/share/fonts/truetype/app-fonts/*.ttf 2>/dev/null | wc -l")
    echo "📊 عدد الخطوط: $SYSTEM_FONT_COUNT"
else
    echo "⚠️  مجلد /usr/share/fonts/truetype/app-fonts غير موجود"
fi

echo ""

# 3. التحقق من fontconfig
echo "=========================================="
echo "3️⃣  التحقق من fontconfig"
echo "=========================================="
echo ""

echo "🔍 البحث عن خطوط Arial:"
docker exec medmap_api fc-list | grep -i arial | head -5
echo ""

echo "🔍 البحث عن خطوط Liberation:"
docker exec medmap_api fc-list | grep -i liberation | head -5
echo ""

echo "🔍 البحث عن خطوط DejaVu:"
docker exec medmap_api fc-list | grep -i dejavu | head -5
echo ""

echo "🔍 البحث عن خطوط عربية:"
docker exec medmap_api fc-list | grep -i kacst | head -5
echo ""

# 4. اختبار قراءة ملف خط
echo "=========================================="
echo "4️⃣  اختبار قراءة الخطوط"
echo "=========================================="
echo ""

if docker exec medmap_api test -f /app/Fonts/ARIAL.TTF; then
    SIZE=$(docker exec medmap_api stat -c%s /app/Fonts/ARIAL.TTF)
    echo "✅ ARIAL.TTF موجود"
    echo "   الحجم: $SIZE بايت"
    echo "   الصلاحيات: $(docker exec medmap_api stat -c%a /app/Fonts/ARIAL.TTF)"
elif docker exec medmap_api test -f /app/Fonts/arial.ttf; then
    SIZE=$(docker exec medmap_api stat -c%s /app/Fonts/arial.ttf)
    echo "✅ arial.ttf موجود"
    echo "   الحجم: $SIZE بايت"
    echo "   الصلاحيات: $(docker exec medmap_api stat -c%a /app/Fonts/arial.ttf)"
else
    echo "⚠️  ARIAL.TTF غير موجود"
fi

echo ""

# 5. التحقق من سجلات التطبيق
echo "=========================================="
echo "5️⃣  سجلات تحميل الخطوط"
echo "=========================================="
echo ""

echo "🔍 البحث في السجلات عن رسائل الخطوط:"
docker logs medmap_api 2>&1 | grep -i "خط\|font" | tail -20

echo ""

# 6. ملخص
echo "=========================================="
echo "📊 الملخص"
echo "=========================================="
echo ""

# حساب الإحصائيات
APP_FONTS=0
SYSTEM_FONTS=0
FC_FONTS=0

if docker exec medmap_api test -d /app/Fonts; then
    APP_FONTS=$(docker exec medmap_api sh -c "ls /app/Fonts/*.TTF /app/Fonts/*.ttf 2>/dev/null | wc -l")
fi

if docker exec medmap_api test -d /usr/share/fonts/truetype/app-fonts; then
    SYSTEM_FONTS=$(docker exec medmap_api sh -c "ls /usr/share/fonts/truetype/app-fonts/*.TTF /usr/share/fonts/truetype/app-fonts/*.ttf 2>/dev/null | wc -l")
fi

FC_FONTS=$(docker exec medmap_api fc-list | wc -l)

echo "📁 خطوط في /app/Fonts: $APP_FONTS"
echo "📁 خطوط في مجلد النظام: $SYSTEM_FONTS"
echo "🔧 خطوط في fontconfig: $FC_FONTS"
echo ""

if [ "$APP_FONTS" -gt 0 ]; then
    echo "✅ الخطوط متاحة للتطبيق"
else
    echo "❌ لا توجد خطوط في /app/Fonts"
fi

if [ "$SYSTEM_FONTS" -gt 0 ]; then
    echo "✅ الخطوط متاحة للنظام"
else
    echo "⚠️  لا توجد خطوط في مجلد النظام"
fi

if [ "$FC_FONTS" -gt 50 ]; then
    echo "✅ fontconfig يعمل بشكل صحيح"
else
    echo "⚠️  fontconfig قد لا يعمل بشكل صحيح"
fi

echo ""
echo "=========================================="
echo "✅ انتهى الفحص"
echo "=========================================="
echo ""

# نصائح
if [ "$APP_FONTS" -eq 0 ]; then
    echo "💡 نصيحة: لإضافة خطوط:"
    echo "   1. ضع الخطوط في publish/Fonts/"
    echo "   2. أعد بناء Docker: docker-compose build api"
    echo "   3. أعد تشغيل الحاوية: docker-compose up -d api"
    echo ""
fi

