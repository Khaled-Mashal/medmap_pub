# استخدام صورة ASP.NET Core Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base

# تثبيت المكتبات المطلوبة لـ DevExpress و System.Drawing والخطوط
RUN apt-get update && apt-get install -y \
    libgdiplus \
    libc6-dev \
    fontconfig \
    software-properties-common \
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

# نسخ جميع الملفات المنشورة
COPY . .

# نسخ خطوط Windows إذا كانت موجودة (اختياري)
RUN if [ -d "windows-fonts" ]; then \
        mkdir -p /usr/share/fonts/truetype/msfonts && \
        cp -r windows-fonts/*.ttf /usr/share/fonts/truetype/msfonts/ 2>/dev/null || true; \
    fi

# تحديث كاش الخطوط
RUN fc-cache -f -v

# إنشاء مجلد uploads إذا لم يكن موجوداً
RUN mkdir -p /app/wwwroot/uploads && chmod -R 777 /app/wwwroot/uploads

# تعيين صلاحيات التنفيذ للملف الرئيسي
RUN chmod +x /app/medicalservices_api

# تعيين متغيرات البيئة
ENV ASPNETCORE_URLS=http://+:80
ENV ASPNETCORE_ENVIRONMENT=Production

# نقطة الدخول
ENTRYPOINT ["./medicalservices_api"]

