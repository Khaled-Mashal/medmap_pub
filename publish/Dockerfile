# استخدام صورة ASP.NET Core Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base

# تثبيت المكتبات المطلوبة لـ DevExpress و System.Drawing
RUN apt-get update && apt-get install -y \
    libgdiplus \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
EXPOSE 80
EXPOSE 443

# نسخ جميع الملفات المنشورة
COPY . .

# إنشاء مجلد uploads إذا لم يكن موجوداً
RUN mkdir -p /app/wwwroot/uploads && chmod -R 777 /app/wwwroot/uploads

# تعيين صلاحيات التنفيذ للملف الرئيسي
RUN chmod +x /app/medicalservices_api

# تعيين متغيرات البيئة
ENV ASPNETCORE_URLS=http://+:80
ENV ASPNETCORE_ENVIRONMENT=Production

# نقطة الدخول
ENTRYPOINT ["./medicalservices_api"]

