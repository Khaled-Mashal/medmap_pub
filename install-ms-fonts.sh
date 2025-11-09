#!/bin/bash

# سكريبت لنسخ خطوط Microsoft من Windows إلى Docker

echo "=========================================="
echo "  تثبيت خطوط Microsoft"
echo "=========================================="
echo ""

# التحقق من وجود مجلد الخطوط
if [ ! -d "publish/windows-fonts" ]; then
    mkdir -p publish/windows-fonts
fi

echo "📝 تعليمات:"
echo ""
echo "1. انسخ الخطوط من Windows:"
echo "   المسار: C:\\Windows\\Fonts"
echo ""
echo "2. الخطوط المطلوبة:"
echo "   - arial.ttf"
echo "   - times.ttf"
echo "   - cour.ttf"
echo "   - verdana.ttf"
echo "   - tahoma.ttf"
echo "   - arialbd.ttf (Arial Bold)"
echo "   - timesbd.ttf (Times Bold)"
echo "   - courbd.ttf (Courier Bold)"
echo ""
echo "3. انسخها إلى المجلد:"
echo "   publish/windows-fonts/"
echo ""
echo "4. ثم قم بإعادة بناء Docker:"
echo "   docker-compose build api"
echo ""

# التحقق من وجود الخطوط
FONTS_FOUND=0
FONTS_NEEDED=(
    "arial.ttf"
    "times.ttf"
    "cour.ttf"
    "verdana.ttf"
    "tahoma.ttf"
)

echo "🔍 التحقق من الخطوط الموجودة:"
echo ""

for font in "${FONTS_NEEDED[@]}"; do
    if [ -f "publish/windows-fonts/$font" ]; then
        echo "✅ $font"
        ((FONTS_FOUND++))
    else
        echo "❌ $font (غير موجود)"
    fi
done

echo ""
echo "=========================================="
echo "📊 النتيجة: $FONTS_FOUND من ${#FONTS_NEEDED[@]} خطوط موجودة"
echo "=========================================="
echo ""

if [ $FONTS_FOUND -eq ${#FONTS_NEEDED[@]} ]; then
    echo "✅ جميع الخطوط موجودة!"
    echo ""
    echo "الآن قم بإعادة بناء Docker:"
    echo "  docker-compose build api"
    echo "  docker-compose up -d api"
else
    echo "⚠️  بعض الخطوط مفقودة"
    echo ""
    echo "لنسخ الخطوط من Windows:"
    echo ""
    echo "في Windows PowerShell:"
    echo "  cd C:\\Windows\\Fonts"
    echo "  Copy-Item arial.ttf,times.ttf,cour.ttf,verdana.ttf,tahoma.ttf <مسار_المشروع>\\publish\\windows-fonts\\"
fi

echo ""

