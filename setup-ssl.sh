#!/bin/bash

# سكريبت إعداد SSL باستخدام Let's Encrypt

DOMAIN="medmapgloble.com"
DOMAIN2="chatboootai.cloud"
EMAIL="admin@medmapgloble.com"  # غيّر هذا إلى بريدك الإلكتروني

echo "=========================================="
echo "  إعداد SSL لـ MedMap و ChatBootAI"
echo "=========================================="
echo ""
echo "⚠️  تأكد من:"
echo "   1. النطاق $DOMAIN يشير إلى هذا السيرفر"
echo "   2. النطاق $DOMAIN2 يشير إلى هذا السيرفر"
echo "   3. المنفذ 80 مفتوح في الجدار الناري"
echo "   4. المنفذ 443 مفتوح في الجدار الناري"
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

# الحصول على الشهادة للدومين الأول
echo "🔐 الحصول على شهادة SSL للدومين الأول ($DOMAIN)..."
sudo certbot certonly --standalone \
    -d $DOMAIN \
    -d www.$DOMAIN \
    --email $EMAIL \
    --agree-tos \
    --non-interactive

if [ $? -ne 0 ]; then
    echo "❌ فشل الحصول على الشهادة للدومين الأول"
    echo "🚀 إعادة تشغيل Nginx..."
    docker-compose start nginx
    exit 1
fi

# الحصول على الشهادة للدومين الثاني
echo "🔐 الحصول على شهادة SSL للدومين الثاني ($DOMAIN2)..."
sudo certbot certonly --standalone \
    -d $DOMAIN2 \
    -d www.$DOMAIN2 \
    --email $EMAIL \
    --agree-tos \
    --non-interactive

if [ $? -ne 0 ]; then
    echo "❌ فشل الحصول على الشهادة للدومين الثاني"
    echo "🚀 إعادة تشغيل Nginx..."
    docker-compose start nginx
    exit 1
fi

# نسخ الشهادات للدومين الأول
echo "📋 نسخ شهادات الدومين الأول..."
sudo mkdir -p nginx/ssl
sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem nginx/ssl/fullchain.pem
sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem nginx/ssl/privkey.pem

# نسخ الشهادات للدومين الثاني
echo "📋 نسخ شهادات الدومين الثاني..."
sudo cp /etc/letsencrypt/live/$DOMAIN2/fullchain.pem nginx/ssl/chatboootai_fullchain.pem
sudo cp /etc/letsencrypt/live/$DOMAIN2/privkey.pem nginx/ssl/chatboootai_privkey.pem

# تعيين الصلاحيات
sudo chmod 644 nginx/ssl/*.pem

# تفعيل إعدادات SSL في Nginx للدومين الأول
echo "⚙️  تفعيل إعدادات SSL للدومين الأول..."
sed -i 's/# server {/server {/g' nginx/conf.d/medmap.conf
sed -i 's/#     /    /g' nginx/conf.d/medmap.conf
sed -i 's/# }/}/g' nginx/conf.d/medmap.conf

# تفعيل إعدادات SSL في Nginx للدومين الثاني
echo "⚙️  تفعيل إعدادات SSL للدومين الثاني..."
sed -i 's/# server {/server {/g' nginx/conf.d/chatboootai.conf
sed -i 's/#     /    /g' nginx/conf.d/chatboootai.conf
sed -i 's/# }/}/g' nginx/conf.d/chatboootai.conf

# إعادة تشغيل Nginx
echo "🚀 إعادة تشغيل Nginx..."
docker-compose start nginx
docker-compose restart nginx

# إعداد التجديد التلقائي
echo "🔄 إعداد التجديد التلقائي..."
SCRIPT_DIR=$(pwd)
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $SCRIPT_DIR/nginx/ssl/fullchain.pem && cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $SCRIPT_DIR/nginx/ssl/privkey.pem && cp /etc/letsencrypt/live/$DOMAIN2/fullchain.pem $SCRIPT_DIR/nginx/ssl/chatboootai_fullchain.pem && cp /etc/letsencrypt/live/$DOMAIN2/privkey.pem $SCRIPT_DIR/nginx/ssl/chatboootai_privkey.pem && chmod 644 $SCRIPT_DIR/nginx/ssl/*.pem && cd $SCRIPT_DIR && docker-compose restart nginx") | crontab -

echo ""
echo "=========================================="
echo "✅ تم إعداد SSL بنجاح!"
echo "=========================================="
echo ""
echo "🌐 يمكنك الآن الوصول إلى:"
echo "   الدومين الأول:"
echo "   - https://$DOMAIN"
echo "   - https://www.$DOMAIN"
echo ""
echo "   الدومين الثاني:"
echo "   - https://$DOMAIN2"
echo "   - https://www.$DOMAIN2"
echo ""
echo "🔄 سيتم تجديد الشهادات تلقائياً كل 3 أشهر"
echo ""

