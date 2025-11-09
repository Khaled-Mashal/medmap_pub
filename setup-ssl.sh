#!/bin/bash

# سكريبت إعداد SSL باستخدام Let's Encrypt

DOMAIN="medmapgloble.com"
EMAIL="admin@medmapgloble.com"  # غيّر هذا إلى بريدك الإلكتروني

echo "=========================================="
echo "  إعداد SSL لـ MedMap"
echo "=========================================="
echo ""
echo "⚠️  تأكد من:"
echo "   1. النطاق $DOMAIN يشير إلى هذا السيرفر"
echo "   2. المنفذ 80 مفتوح في الجدار الناري"
echo "   3. المنفذ 443 مفتوح في الجدار الناري"
echo ""
read -p "هل تريد المتابعة؟ (y/n): " confirm

if [ "$confirm" != "y" ]; then
    echo "❌ تم الإلغاء"
    exit 0
fi

# التحقق من تثبيت Certbot
if ! command -v certbot &> /dev/null; then
    echo "📦 تثبيت Certbot..."
    sudo apt-get update
    sudo apt-get install -y certbot
fi

# إيقاف Nginx مؤقتاً للحصول على الشهادة
echo "🛑 إيقاف Nginx مؤقتاً..."
docker-compose stop nginx

# الحصول على الشهادة
echo "🔐 الحصول على شهادة SSL..."
sudo certbot certonly --standalone \
    -d $DOMAIN \
    -d www.$DOMAIN \
    --email $EMAIL \
    --agree-tos \
    --non-interactive

if [ $? -ne 0 ]; then
    echo "❌ فشل الحصول على الشهادة"
    echo "🚀 إعادة تشغيل Nginx..."
    docker-compose start nginx
    exit 1
fi

# نسخ الشهادات
echo "📋 نسخ الشهادات..."
sudo mkdir -p nginx/ssl
sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem nginx/ssl/
sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem nginx/ssl/
sudo chmod 644 nginx/ssl/*.pem

# تفعيل إعدادات SSL في Nginx
echo "⚙️  تفعيل إعدادات SSL..."
sed -i 's/# server {/server {/g' nginx/conf.d/medmap.conf
sed -i 's/#     /    /g' nginx/conf.d/medmap.conf
sed -i 's/# }/}/g' nginx/conf.d/medmap.conf

# إعادة تشغيل Nginx
echo "🚀 إعادة تشغيل Nginx..."
docker-compose start nginx
docker-compose restart nginx

# إعداد التجديد التلقائي
echo "🔄 إعداد التجديد التلقائي..."
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && cp /etc/letsencrypt/live/$DOMAIN/*.pem $(pwd)/nginx/ssl/ && docker-compose restart nginx") | crontab -

echo ""
echo "=========================================="
echo "✅ تم إعداد SSL بنجاح!"
echo "=========================================="
echo ""
echo "🌐 يمكنك الآن الوصول إلى:"
echo "   - https://$DOMAIN"
echo "   - https://www.$DOMAIN"
echo ""
echo "🔄 سيتم تجديد الشهادة تلقائياً كل 3 أشهر"
echo ""

