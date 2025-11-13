# استخدام صورة ASP.NET Core Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base

# تثبيت المكتبات الأساسية المطلوبة
RUN apt-get update && apt-get install -y \
    libc6 \
    libicu-dev \
    libfontconfig1 \
    libgdiplus \
    libc6-dev \
    fontconfig \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# تثبيت الخطوط
RUN apt-get update && apt-get install -y \
    fonts-dejavu \
    fonts-dejavu-core \
    fonts-dejavu-extra \
    fonts-liberation \
    fonts-liberation2 \
    fonts-noto \
    fonts-noto-core \
    fonts-noto-ui-core \
    fonts-noto-color-emoji \
    fonts-arabeyes \
    fonts-kacst \
    fonts-kacst-one \
    fonts-farsiweb \
    fonts-freefont-ttf \
    fonts-opensymbol \
    && rm -rf /var/lib/apt/lists/*

# (اختياري) تثبيت خطوط Microsoft Core Fonts
# قم بإلغاء التعليق إذا كنت تريد استخدام الخطوط الأصلية
# ملاحظة: للتطوير والاختبار فقط - استخدم البدائل المفتوحة للإنتاج
# RUN echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections && \
#     echo "deb http://deb.debian.org/debian bookworm contrib" >> /etc/apt/sources.list && \
#     apt-get update && \
#     apt-get install -y ttf-mscorefonts-installer && \
#     rm -rf /var/lib/apt/lists/*

WORKDIR /app
EXPOSE 80
EXPOSE 443

# نسخ إعدادات الخطوط
COPY fonts.conf /etc/fonts/local.conf

# نسخ جميع الملفات المنشورة (يشمل مجلد Fonts)
COPY . .

# التأكد من وجود مجلد Fonts وصلاحياته
RUN if [ -d "Fonts" ]; then \
        chmod -R 755 Fonts && \
        echo "✅ مجلد Fonts موجود في /app/Fonts"; \
        ls -la Fonts/ | head -10; \
    else \
        echo "⚠️ تحذير: مجلد Fonts غير موجود!"; \
    fi

# نسخ خطوط التطبيق إلى مجلدات Linux النظامية
RUN if [ -d "Fonts" ]; then \
        echo "📦 نسخ الخطوط إلى مجلدات Linux..."; \
        \
        # نسخ إلى /usr/share/fonts/truetype/app-fonts
        mkdir -p /usr/share/fonts/truetype/app-fonts && \
        cp Fonts/*.TTF /usr/share/fonts/truetype/app-fonts/ 2>/dev/null || true && \
        cp Fonts/*.ttf /usr/share/fonts/truetype/app-fonts/ 2>/dev/null || true && \
        echo "✅ تم النسخ إلى: /usr/share/fonts/truetype/app-fonts"; \
        \
        # نسخ إلى /usr/local/share/fonts
        mkdir -p /usr/local/share/fonts && \
        cp Fonts/*.TTF /usr/local/share/fonts/ 2>/dev/null || true && \
        cp Fonts/*.ttf /usr/local/share/fonts/ 2>/dev/null || true && \
        echo "✅ تم النسخ إلى: /usr/local/share/fonts"; \
        \
        # نسخ إلى /usr/share/fonts/truetype/msttcorefonts
        mkdir -p /usr/share/fonts/truetype/msttcorefonts && \
        cp Fonts/*.TTF /usr/share/fonts/truetype/msttcorefonts/ 2>/dev/null || true && \
        cp Fonts/*.ttf /usr/share/fonts/truetype/msttcorefonts/ 2>/dev/null || true && \
        echo "✅ تم النسخ إلى: /usr/share/fonts/truetype/msttcorefonts"; \
        \
        # عرض عدد الخطوط
        FONT_COUNT=$(ls Fonts/*.TTF Fonts/*.ttf 2>/dev/null | wc -l); \
        echo "📊 تم نسخ $FONT_COUNT خط إلى 3 مجلدات"; \
    fi

# نسخ خطوط Windows إذا كانت موجودة (اختياري)
RUN if [ -d "windows-fonts" ]; then \
        mkdir -p /usr/share/fonts/truetype/msfonts && \
        mkdir -p /usr/local/share/fonts && \
        cp windows-fonts/*.ttf /usr/share/fonts/truetype/msfonts/ 2>/dev/null || true && \
        cp windows-fonts/*.TTF /usr/share/fonts/truetype/msfonts/ 2>/dev/null || true && \
        cp windows-fonts/*.ttf /usr/local/share/fonts/ 2>/dev/null || true && \
        cp windows-fonts/*.TTF /usr/local/share/fonts/ 2>/dev/null || true && \
        echo "✅ تم نسخ خطوط Windows من مجلد windows-fonts"; \
    fi

# تعيين الصلاحيات الصحيحة لمجلدات الخطوط
RUN chmod -R 755 /usr/share/fonts/truetype/app-fonts 2>/dev/null || true && \
    chmod -R 755 /usr/share/fonts/truetype/msttcorefonts 2>/dev/null || true && \
    chmod -R 755 /usr/local/share/fonts 2>/dev/null || true && \
    echo "✅ تم تعيين الصلاحيات"

# تحديث كاش الخطوط في جميع المجلدات
RUN fc-cache -f -v && \
    echo "✅ تم تحديث كاش الخطوط"

# إنشاء مجلد uploads إذا لم يكن موجوداً
RUN mkdir -p /app/wwwroot/uploads && chmod -R 777 /app/wwwroot/uploads

# تعيين صلاحيات التنفيذ للملف الرئيسي
RUN chmod +x /app/medicalservices_api

# تعيين متغيرات البيئة
ENV ASPNETCORE_URLS=http://+:80
ENV ASPNETCORE_ENVIRONMENT=Production

# نقطة الدخول
ENTRYPOINT ["./medicalservices_api"]

