#!/bin/bash

# سكريبت للتحقق من Dependencies المطلوبة لـ Skia و DevExpress

echo "=========================================="
echo "  🔍 فحص Dependencies لـ Skia و DevExpress"
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

# 1. فحص Native Libraries
echo "=========================================="
echo "1️⃣  فحص Native Libraries"
echo "=========================================="
echo ""

echo "🔍 فحص libfontconfig:"
if docker exec medmap_api ldconfig -p | grep -q fontconfig; then
    echo "✅ libfontconfig موجودة"
    docker exec medmap_api ldconfig -p | grep fontconfig | head -3
else
    echo "❌ libfontconfig مفقودة"
fi
echo ""

echo "🔍 فحص libfreetype:"
if docker exec medmap_api ldconfig -p | grep -q freetype; then
    echo "✅ libfreetype موجودة"
    docker exec medmap_api ldconfig -p | grep freetype | head -3
else
    echo "❌ libfreetype مفقودة"
fi
echo ""

echo "🔍 فحص libgdiplus:"
if docker exec medmap_api ldconfig -p | grep -q gdiplus; then
    echo "✅ libgdiplus موجودة"
    docker exec medmap_api ldconfig -p | grep gdiplus | head -3
else
    echo "❌ libgdiplus مفقودة"
fi
echo ""

# 2. فحص متغيرات البيئة
echo "=========================================="
echo "2️⃣  فحص متغيرات البيئة"
echo "=========================================="
echo ""

echo "🔍 FONTCONFIG_PATH:"
FONTCONFIG_PATH=$(docker exec medmap_api printenv FONTCONFIG_PATH 2>/dev/null)
if [ -n "$FONTCONFIG_PATH" ]; then
    echo "✅ $FONTCONFIG_PATH"
else
    echo "⚠️  غير معرّف"
fi
echo ""

echo "🔍 FONTCONFIG_FILE:"
FONTCONFIG_FILE=$(docker exec medmap_api printenv FONTCONFIG_FILE 2>/dev/null)
if [ -n "$FONTCONFIG_FILE" ]; then
    echo "✅ $FONTCONFIG_FILE"
else
    echo "⚠️  غير معرّف"
fi
echo ""

echo "🔍 SKIA_FONT_CACHE_LIMIT:"
SKIA_CACHE=$(docker exec medmap_api printenv SKIA_FONT_CACHE_LIMIT 2>/dev/null)
if [ -n "$SKIA_CACHE" ]; then
    echo "✅ $SKIA_CACHE"
else
    echo "⚠️  غير معرّف"
fi
echo ""

echo "🔍 DOTNET_SYSTEM_GLOBALIZATION_INVARIANT:"
GLOBALIZATION=$(docker exec medmap_api printenv DOTNET_SYSTEM_GLOBALIZATION_INVARIANT 2>/dev/null)
if [ -n "$GLOBALIZATION" ]; then
    echo "✅ $GLOBALIZATION"
else
    echo "⚠️  غير معرّف"
fi
echo ""

# 3. فحص fontconfig
echo "=========================================="
echo "3️⃣  فحص fontconfig"
echo "=========================================="
echo ""

echo "🔍 فحص إعدادات fontconfig:"
if docker exec medmap_api test -f /etc/fonts/local.conf; then
    echo "✅ ملف /etc/fonts/local.conf موجود"
else
    echo "⚠️  ملف /etc/fonts/local.conf غير موجود"
fi
echo ""

echo "🔍 اختبار fc-match للخطوط:"
echo "   Arial:"
docker exec medmap_api fc-match Arial 2>/dev/null || echo "   ❌ فشل"
echo ""
echo "   Liberation Sans:"
docker exec medmap_api fc-match "Liberation Sans" 2>/dev/null || echo "   ❌ فشل"
echo ""
echo "   DejaVu Sans:"
docker exec medmap_api fc-match "DejaVu Sans" 2>/dev/null || echo "   ❌ فشل"
echo ""

# 4. فحص الخطوط المتاحة
echo "=========================================="
echo "4️⃣  فحص الخطوط المتاحة"
echo "=========================================="
echo ""

echo "🔍 خطوط Arial:"
ARIAL_COUNT=$(docker exec medmap_api fc-list | grep -i arial | wc -l)
if [ "$ARIAL_COUNT" -gt 0 ]; then
    echo "✅ وجد $ARIAL_COUNT خط Arial"
    docker exec medmap_api fc-list | grep -i arial | head -5
else
    echo "⚠️  لم يتم العثور على خطوط Arial"
fi
echo ""

echo "🔍 خطوط Liberation:"
LIBERATION_COUNT=$(docker exec medmap_api fc-list | grep -i liberation | wc -l)
if [ "$LIBERATION_COUNT" -gt 0 ]; then
    echo "✅ وجد $LIBERATION_COUNT خط Liberation"
    docker exec medmap_api fc-list | grep -i liberation | head -5
else
    echo "⚠️  لم يتم العثور على خطوط Liberation"
fi
echo ""

echo "🔍 خطوط عربية:"
ARABIC_COUNT=$(docker exec medmap_api fc-list :lang=ar | wc -l)
if [ "$ARABIC_COUNT" -gt 0 ]; then
    echo "✅ وجد $ARABIC_COUNT خط عربي"
    docker exec medmap_api fc-list :lang=ar | head -5
else
    echo "⚠️  لم يتم العثور على خطوط عربية"
fi
echo ""

# 5. فحص مجلدات الخطوط
echo "=========================================="
echo "5️⃣  فحص مجلدات الخطوط"
echo "=========================================="
echo ""

FONT_DIRS=(
    "/app/Fonts"
    "/usr/share/fonts/truetype/app-fonts"
    "/usr/local/share/fonts"
    "/usr/share/fonts/truetype/msttcorefonts"
    "/usr/share/fonts/truetype/liberation"
    "/usr/share/fonts/truetype/dejavu"
)

for dir in "${FONT_DIRS[@]}"; do
    echo "📂 $dir:"
    if docker exec medmap_api test -d "$dir"; then
        FONT_COUNT=$(docker exec medmap_api sh -c "find $dir -name '*.ttf' -o -name '*.TTF' 2>/dev/null | wc -l")
        echo "   ✅ موجود - عدد الخطوط: $FONT_COUNT"
    else
        echo "   ⚠️  غير موجود"
    fi
done
echo ""

# 6. فحص السجلات
echo "=========================================="
echo "6️⃣  فحص سجلات التطبيق"
echo "=========================================="
echo ""

echo "🔍 البحث عن رسائل Skia:"
docker logs medmap_api 2>&1 | grep -i "skia\|font" | tail -10
echo ""

# 7. الملخص
echo "=========================================="
echo "📊 الملخص"
echo "=========================================="
echo ""

ISSUES=0

# فحص المكتبات
if ! docker exec medmap_api ldconfig -p | grep -q fontconfig; then
    echo "❌ libfontconfig مفقودة"
    ISSUES=$((ISSUES + 1))
fi

if ! docker exec medmap_api ldconfig -p | grep -q freetype; then
    echo "❌ libfreetype مفقودة"
    ISSUES=$((ISSUES + 1))
fi

# فحص الخطوط
if [ "$ARIAL_COUNT" -eq 0 ] && [ "$LIBERATION_COUNT" -eq 0 ]; then
    echo "❌ لا توجد خطوط Arial أو Liberation"
    ISSUES=$((ISSUES + 1))
fi

if [ "$ARABIC_COUNT" -eq 0 ]; then
    echo "⚠️  لا توجد خطوط عربية"
    ISSUES=$((ISSUES + 1))
fi

# فحص متغيرات البيئة
if [ -z "$FONTCONFIG_PATH" ]; then
    echo "⚠️  FONTCONFIG_PATH غير معرّف"
    ISSUES=$((ISSUES + 1))
fi

echo ""
if [ "$ISSUES" -eq 0 ]; then
    echo "✅ جميع الفحوصات نجحت!"
    echo "✅ النظام جاهز لتشغيل DevExpress مع Skia"
else
    echo "⚠️  وجد $ISSUES مشكلة"
    echo ""
    echo "💡 الحلول المقترحة:"
    echo "   1. أعد بناء الصورة: docker-compose build api --no-cache"
    echo "   2. أعد تشغيل الحاوية: docker-compose up -d api"
    echo "   3. تحقق من Dockerfile"
fi

echo ""
echo "=========================================="
echo "✅ انتهى الفحص"
echo "=========================================="

