#!/bin/bash

# سكريبت عرض السجلات

echo "=========================================="
echo "  سجلات MedMap"
echo "=========================================="
echo ""
echo "اختر الخدمة:"
echo "  1) جميع الخدمات"
echo "  2) API"
echo "  3) PostgreSQL"
echo "  4) Nginx"
echo ""
read -p "الاختيار [1-4]: " choice

case $choice in
    1)
        echo "📋 عرض سجلات جميع الخدمات..."
        docker-compose logs -f
        ;;
    2)
        echo "📋 عرض سجلات API..."
        docker-compose logs -f api
        ;;
    3)
        echo "📋 عرض سجلات PostgreSQL..."
        docker-compose logs -f postgres
        ;;
    4)
        echo "📋 عرض سجلات Nginx..."
        docker-compose logs -f nginx
        ;;
    *)
        echo "❌ اختيار غير صحيح"
        exit 1
        ;;
esac

