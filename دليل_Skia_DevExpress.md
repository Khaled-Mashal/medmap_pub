# 🎨 دليل إعداد Skia و DevExpress على Linux

## 📋 نظرة عامة

تم إعداد المشروع بشكل كامل لدعم **DevExpress Reports** مع **Skia rendering engine** على Linux.

---

## ✅ ما تم تطبيقه

### 1️⃣ **Native Libraries المطلوبة**

تم تثبيت جميع المكتبات الأساسية لـ Skia:

```dockerfile
# في Dockerfile
RUN apt-get update && apt-get install -y \
    # Native libraries أساسية لـ Skia
    libfontconfig1 \
    libfontconfig1-dev \
    libfreetype6 \
    libfreetype6-dev \
    # مكتبات أساسية
    libc6 \
    libicu-dev \
    libgdiplus \
    libc6-dev \
    fontconfig
```

### 2️⃣ **الخطوط**

تم تثبيت 3 مستويات من الخطوط:

#### أ. خطوط مفتوحة المصدر:
- ✅ **Liberation Fonts** (بديل Arial, Times, Courier)
- ✅ **DejaVu Fonts** (بديل Verdana, Tahoma)
- ✅ **Noto Fonts** (دعم Unicode شامل)
- ✅ **KACST Fonts** (خطوط عربية)

#### ب. خطوط Microsoft Core Fonts:
- ✅ تم تثبيت `ttf-mscorefonts-installer`
- ✅ يشمل: Arial, Times New Roman, Courier New, Verdana, Tahoma

#### ج. خطوط التطبيق:
- ✅ مجلد `/app/Fonts` يحتوي على خطوط Arial
- ✅ منسوخة إلى 3 مجلدات في النظام

### 3️⃣ **متغيرات البيئة**

تم تعيين جميع المتغيرات المطلوبة:

```bash
FONTCONFIG_PATH=/etc/fonts:/usr/share/fontconfig:/app/Fonts
FONTCONFIG_FILE=/etc/fonts/fonts.conf
SKIA_FONT_CACHE_LIMIT=8
DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
```

### 4️⃣ **إعدادات fontconfig**

تم إنشاء ملف `/etc/fonts/local.conf` مع:
- ✅ مسارات الخطوط
- ✅ توجيه تلقائي للخطوط (Font Aliases)
- ✅ تحسينات الأداء

### 5️⃣ **مجلدات الخطوط**

الخطوط متاحة في 4 مواقع:

| المجلد | الاستخدام | الخطوط |
|--------|-----------|--------|
| `/app/Fonts` | DevExpress (قراءة مباشرة) | 10 خطوط Arial |
| `/usr/share/fonts/truetype/app-fonts` | fontconfig | 10 خطوط Arial |
| `/usr/local/share/fonts` | النظام | 10 خطوط Arial |
| `/usr/share/fonts/truetype/msttcorefonts` | Microsoft Fonts | Arial, Times, Courier, etc. |

---

## 🚀 الاستخدام

### التحقق من الإعداد:

```bash
# فحص شامل لـ Skia Dependencies
make check-skia

# أو
./check-skia-dependencies.sh
```

### فحص الخطوط فقط:

```bash
make check-fonts

# أو
./check-fonts.sh
```

### إعادة البناء:

```bash
# إعادة بناء كاملة
docker-compose build api --no-cache

# إعادة التشغيل
docker-compose up -d api

# فحص السجلات
docker logs medmap_api | grep -i "skia\|font"
```

---

## 🔍 التحقق اليدوي

### 1. فحص Native Libraries:

```bash
# فحص libfontconfig
docker exec medmap_api ldconfig -p | grep fontconfig

# فحص libfreetype
docker exec medmap_api ldconfig -p | grep freetype

# فحص libgdiplus
docker exec medmap_api ldconfig -p | grep gdiplus
```

### 2. فحص متغيرات البيئة:

```bash
docker exec medmap_api printenv | grep -E "FONT|SKIA|GLOBALIZATION"
```

### 3. فحص الخطوط:

```bash
# اختبار fc-match
docker exec medmap_api fc-match Arial
docker exec medmap_api fc-match "Liberation Sans"

# عرض جميع الخطوط
docker exec medmap_api fc-list | grep -i arial
docker exec medmap_api fc-list :lang=ar
```

### 4. فحص المجلدات:

```bash
# مجلد التطبيق
docker exec medmap_api ls -la /app/Fonts/

# مجلدات النظام
docker exec medmap_api ls -la /usr/share/fonts/truetype/app-fonts/
docker exec medmap_api ls -la /usr/local/share/fonts/
docker exec medmap_api ls -la /usr/share/fonts/truetype/msttcorefonts/
```

---

## 📊 الرسائل المتوقعة

### عند بدء التطبيق:

```
✅ تم تفعيل محرك Skia لـ DevExpress بنجاح
✅ تم تحميل 9 من 10 خطوط Arial
✅ خطوط Arial متوفرة: Arial, Arial Unicode MS, Arial Black
```

### عند بناء Docker:

```
✅ libfontconfig موجودة
✅ libfreetype موجودة
✅ خطوط Arial متاحة
✅ خطوط Liberation متاحة
✅ تم تحديث كاش الخطوط
```

### عند تصدير PDF:

```
✅ تم تطبيق خط Arial على X عنصر في Y bands
✅ تم تصدير PDF بنجاح - الحجم: X bytes
```

---

## 🐛 استكشاف الأخطاء

### المشكلة 1: "Skia native libraries not found"

**الأعراض:**
```
❌ فشل في تفعيل Skia
⚠️ تحذير: مشكلة في تصيير PDF
```

**الحل:**
```bash
# تحقق من المكتبات
docker exec medmap_api ldconfig -p | grep fontconfig
docker exec medmap_api ldconfig -p | grep freetype

# إذا كانت مفقودة، أعد البناء
docker-compose build api --no-cache
```

---

### المشكلة 2: "Font not rendering correctly"

**الأعراض:**
```
⚠️ الخط لا يظهر بشكل صحيح في PDF
⚠️ النصوص العربية مشوهة
```

**الحل:**
```bash
# فحص الخطوط
docker exec medmap_api fc-match Arial
docker exec medmap_api fc-list :lang=ar

# إعادة بناء كاش الخطوط
docker exec medmap_api fc-cache -f -v

# إعادة تشغيل الحاوية
docker-compose restart api
```

---

### المشكلة 3: "PDF rendering fails"

**الأعراض:**
```
❌ فشل في تصدير PDF
⚠️ حجم PDF صغير جداً (<1KB)
```

**الحل:**
```bash
# فحص متغيرات البيئة
docker exec medmap_api printenv | grep FONT

# فحص السجلات
docker logs medmap_api | grep -i "error\|exception"

# فحص مجلد الخطوط
docker exec medmap_api ls -la /app/Fonts/

# إذا كان المجلد فارغاً
docker-compose build api --no-cache
docker-compose up -d api
```

---

### المشكلة 4: "متغيرات البيئة غير معرّفة"

**الأعراض:**
```
⚠️ FONTCONFIG_PATH غير معرّف
⚠️ SKIA_FONT_CACHE_LIMIT غير معرّف
```

**الحل:**
```bash
# تحقق من docker-compose.yml
cat docker-compose.yml | grep -A 10 "environment:"

# أعد تشغيل الحاوية
docker-compose down
docker-compose up -d
```

---

## 📚 الملفات المهمة

### 1. **Dockerfile** (`publish/Dockerfile`)
- تثبيت Native Libraries
- تثبيت الخطوط
- نسخ الخطوط إلى مجلدات النظام
- تعيين متغيرات البيئة

### 2. **docker-compose.yml**
- تعريف متغيرات البيئة
- تعريف Volumes
- إعدادات Healthcheck

### 3. **fonts.conf** (`publish/fonts.conf`)
- مسارات الخطوط
- Font Aliases
- إعدادات fontconfig

### 4. **check-skia-dependencies.sh**
- فحص شامل لـ Skia Dependencies
- فحص Native Libraries
- فحص متغيرات البيئة
- فحص الخطوط

### 5. **check-fonts.sh**
- فحص مجلدات الخطوط
- فحص fontconfig
- عرض إحصائيات الخطوط

---

## 🎯 أفضل الممارسات

### 1. **المراقبة المستمرة:**

```bash
# إضافة إلى crontab
*/15 * * * * /opt/medmap_pub/check-skia-dependencies.sh >> /var/log/skia-check.log
```

### 2. **Healthcheck في Docker:**

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost/api/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### 3. **Logging:**

```bash
# مراقبة السجلات
docker logs -f medmap_api | grep -i "skia\|font\|pdf"
```

---

## 📊 الإحصائيات المتوقعة

بعد الإعداد الصحيح:

| المقياس | القيمة المتوقعة |
|---------|-----------------|
| Native Libraries | 3/3 (fontconfig, freetype, gdiplus) |
| متغيرات البيئة | 4/4 |
| خطوط Arial | 10+ |
| خطوط Liberation | 12+ |
| خطوط عربية | 20+ |
| مجلدات الخطوط | 4/4 |
| معدل نجاح PDF | >95% |

---

## ✅ الخلاصة

تم إعداد المشروع بشكل كامل لدعم:

- ✅ **Skia rendering engine** مع جميع Native Libraries
- ✅ **DevExpress Reports** مع دعم كامل للخطوط
- ✅ **خطوط عربية** مع دعم Unicode
- ✅ **خطوط Microsoft** (Arial, Times, Courier, etc.)
- ✅ **Font Aliases** للتوافق التلقائي
- ✅ **متغيرات البيئة** المحسّنة
- ✅ **أدوات التشخيص** الشاملة

---

## 🚀 الخطوات التالية

```bash
# 1. إعادة البناء
docker-compose build api --no-cache

# 2. إعادة التشغيل
docker-compose up -d api

# 3. الفحص
make check-skia

# 4. اختبار التطبيق
curl http://localhost:5000/api/health
```

---

**تم التحديث:** 2025-11-09  
**الإصدار:** 2.0  
**الحالة:** ✅ جاهز للإنتاج

