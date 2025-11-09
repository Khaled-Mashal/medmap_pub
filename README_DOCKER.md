# دليل نشر MedMap باستخدام Docker

## المتطلبات الأساسية
- Docker و Docker Compose مثبتان على السيرفر
- النطاق medmapgloble.com يشير إلى عنوان IP الخاص بالسيرفر

## خطوات التشغيل

### 1. إعداد المتغيرات البيئية
```bash
# نسخ ملف المتغيرات البيئية
cp .env.example .env

# تعديل الملف وتغيير كلمة المرور
nano .env
```

### 2. بناء وتشغيل الحاويات
```bash
# بناء وتشغيل جميع الخدمات
docker-compose up -d

# التحقق من حالة الحاويات
docker-compose ps

# عرض السجلات
docker-compose logs -f
```

### 3. التحقق من التشغيل
- افتح المتصفح على: http://medmapgloble.com
- أو استخدم عنوان IP: http://YOUR_SERVER_IP

### 4. إعداد SSL (اختياري ولكن موصى به)

#### استخدام Let's Encrypt (مجاني)
```bash
# تثبيت Certbot
sudo apt-get update
sudo apt-get install certbot

# الحصول على الشهادة
sudo certbot certonly --standalone -d medmapgloble.com -d www.medmapgloble.com

# نسخ الشهادات إلى مجلد nginx
sudo mkdir -p nginx/ssl
sudo cp /etc/letsencrypt/live/medmapgloble.com/fullchain.pem nginx/ssl/
sudo cp /etc/letsencrypt/live/medmapgloble.com/privkey.pem nginx/ssl/

# إلغاء التعليق عن إعدادات SSL في nginx/conf.d/medmap.conf
# ثم إعادة تشغيل nginx
docker-compose restart nginx
```

## الأوامر المفيدة

### إدارة الحاويات
```bash
# إيقاف جميع الخدمات
docker-compose down

# إيقاف مع حذف البيانات (احذر!)
docker-compose down -v

# إعادة تشغيل خدمة معينة
docker-compose restart api
docker-compose restart postgres
docker-compose restart nginx

# عرض سجلات خدمة معينة
docker-compose logs -f api
docker-compose logs -f postgres
docker-compose logs -f nginx
```

### النسخ الاحتياطي

#### نسخ احتياطي لقاعدة البيانات
```bash
# إنشاء نسخة احتياطية
docker-compose exec postgres pg_dump -U postgres medical_services_db > backup_$(date +%Y%m%d_%H%M%S).sql

# استعادة من نسخة احتياطية
docker-compose exec -T postgres psql -U postgres medical_services_db < backup_20240101_120000.sql
```

#### نسخ احتياطي للملفات المرفوعة
```bash
# نسخ الملفات
docker run --rm -v medmap_uploads_data:/data -v $(pwd):/backup alpine tar czf /backup/uploads_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .

# استعادة الملفات
docker run --rm -v medmap_uploads_data:/data -v $(pwd):/backup alpine tar xzf /backup/uploads_backup_20240101_120000.tar.gz -C /data
```

### التحديثات
```bash
# تحديث التطبيق
# 1. ضع الملفات الجديدة في مجلد publish
# 2. أعد بناء الصورة
docker-compose build api

# 3. أعد تشغيل الخدمة
docker-compose up -d api
```

### مراقبة الأداء
```bash
# عرض استهلاك الموارد
docker stats

# عرض مساحة التخزين
docker system df

# تنظيف الملفات غير المستخدمة
docker system prune -a
```

## البيانات المحفوظة (Volumes)

البيانات التالية محفوظة بشكل دائم ولن تُحذف عند إعادة تشغيل الحاويات:

1. **postgres_data**: بيانات قاعدة البيانات
2. **uploads_data**: الملفات المرفوعة في wwwroot/uploads
3. **frontend_data**: ملفات الواجهة الأمامية في wwwroot/build
4. **nginx_logs**: سجلات Nginx

## استكشاف الأخطاء

### التطبيق لا يعمل
```bash
# التحقق من السجلات
docker-compose logs api

# الدخول إلى حاوية التطبيق
docker-compose exec api /bin/bash

# التحقق من الاتصال بقاعدة البيانات
docker-compose exec api ping postgres
```

### قاعدة البيانات لا تعمل
```bash
# التحقق من السجلات
docker-compose logs postgres

# الدخول إلى قاعدة البيانات
docker-compose exec postgres psql -U postgres -d medical_services_db
```

### Nginx لا يعمل
```bash
# التحقق من السجلات
docker-compose logs nginx

# اختبار إعدادات Nginx
docker-compose exec nginx nginx -t

# إعادة تحميل الإعدادات
docker-compose exec nginx nginx -s reload
```

## الأمان

### توصيات مهمة:
1. ✅ غيّر كلمة مرور قاعدة البيانات في ملف .env
2. ✅ غيّر JWT SecretKey في appsettings.json
3. ✅ استخدم HTTPS مع شهادة SSL
4. ✅ قم بإعداد جدار ناري (Firewall)
5. ✅ قم بعمل نسخ احتياطية دورية
6. ✅ راقب السجلات بانتظام

## المنافذ المستخدمة
- **80**: HTTP (Nginx)
- **443**: HTTPS (Nginx)
- **5000**: API (داخلي)
- **5432**: PostgreSQL (داخلي)

## الدعم
في حالة وجود مشاكل، تحقق من:
1. السجلات: `docker-compose logs -f`
2. حالة الخدمات: `docker-compose ps`
3. استهلاك الموارد: `docker stats`

