#!/bin/bash

# سكريبت إعداد التنبيهات التلقائية

ALERT_EMAIL="admin@medmapgloble.com"  # غيّر هذا إلى بريدك
ALERT_SCRIPT="/usr/local/bin/medmap-alert.sh"
CHECK_INTERVAL=5  # دقائق

echo "=========================================="
echo "  إعداد نظام التنبيهات - MedMap"
echo "=========================================="
echo ""

read -p "أدخل البريد الإلكتروني للتنبيهات [$ALERT_EMAIL]: " input_email
if [ ! -z "$input_email" ]; then
    ALERT_EMAIL=$input_email
fi

echo "📧 البريد الإلكتروني: $ALERT_EMAIL"
echo ""

# إنشاء سكريبت التنبيهات
echo "📝 إنشاء سكريبت التنبيهات..."
sudo tee $ALERT_SCRIPT > /dev/null << 'EOF'
#!/bin/bash

# سكريبت فحص صحة MedMap وإرسال التنبيهات

ALERT_EMAIL="REPLACE_EMAIL"
PROJECT_DIR="REPLACE_DIR"
LOG_FILE="/var/log/medmap-alerts.log"

cd $PROJECT_DIR

# دالة لإرسال تنبيه
send_alert() {
    local subject="$1"
    local message="$2"
    
    echo "[$(date)] $subject: $message" >> $LOG_FILE
    
    # إرسال بريد إلكتروني (يتطلب تثبيت mailutils)
    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "MedMap Alert: $subject" $ALERT_EMAIL
    fi
}

# فحص حالة الحاويات
check_containers() {
    local down_containers=$(docker-compose ps | grep -c "Exit\|Down")
    
    if [ $down_containers -gt 0 ]; then
        send_alert "Container Down" "عدد $down_containers حاوية متوقفة"
        return 1
    fi
    return 0
}

# فحص استهلاك الذاكرة
check_memory() {
    local mem_usage=$(docker stats --no-stream --format "{{.MemPerc}}" medmap_api | sed 's/%//')
    
    if (( $(echo "$mem_usage > 90" | bc -l) )); then
        send_alert "High Memory Usage" "استهلاك الذاكرة: ${mem_usage}%"
        return 1
    fi
    return 0
}

# فحص استهلاك CPU
check_cpu() {
    local cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" medmap_api | sed 's/%//')
    
    if (( $(echo "$cpu_usage > 90" | bc -l) )); then
        send_alert "High CPU Usage" "استهلاك المعالج: ${cpu_usage}%"
        return 1
    fi
    return 0
}

# فحص مساحة التخزين
check_disk() {
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [ $disk_usage -gt 90 ]; then
        send_alert "Low Disk Space" "مساحة التخزين المستخدمة: ${disk_usage}%"
        return 1
    fi
    return 0
}

# فحص الاتصال بـ API
check_api() {
    if ! curl -f -s http://localhost:5000 > /dev/null; then
        send_alert "API Down" "API لا يستجيب"
        
        # محاولة إعادة التشغيل
        docker-compose restart api
        sleep 10
        
        if ! curl -f -s http://localhost:5000 > /dev/null; then
            send_alert "API Restart Failed" "فشل إعادة تشغيل API"
        else
            send_alert "API Restarted" "تم إعادة تشغيل API بنجاح"
        fi
        return 1
    fi
    return 0
}

# فحص قاعدة البيانات
check_database() {
    if ! docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
        send_alert "Database Down" "قاعدة البيانات لا تستجيب"
        
        # محاولة إعادة التشغيل
        docker-compose restart postgres
        sleep 10
        
        if ! docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
            send_alert "Database Restart Failed" "فشل إعادة تشغيل قاعدة البيانات"
        else
            send_alert "Database Restarted" "تم إعادة تشغيل قاعدة البيانات بنجاح"
        fi
        return 1
    fi
    return 0
}

# فحص الأخطاء في السجلات
check_errors() {
    local error_count=$(docker-compose logs --since 5m | grep -i "error\|exception\|fatal" | wc -l)
    
    if [ $error_count -gt 10 ]; then
        send_alert "High Error Rate" "عدد الأخطاء في آخر 5 دقائق: $error_count"
        return 1
    fi
    return 0
}

# تشغيل جميع الفحوصات
echo "[$(date)] بدء الفحص..." >> $LOG_FILE

check_containers
check_memory
check_cpu
check_disk
check_api
check_database
check_errors

echo "[$(date)] اكتمل الفحص" >> $LOG_FILE
EOF

# استبدال المتغيرات
sudo sed -i "s|REPLACE_EMAIL|$ALERT_EMAIL|g" $ALERT_SCRIPT
sudo sed -i "s|REPLACE_DIR|$(pwd)|g" $ALERT_SCRIPT

# إعطاء صلاحيات التنفيذ
sudo chmod +x $ALERT_SCRIPT

# إضافة إلى Cron
echo "⏰ إضافة إلى Cron..."
(crontab -l 2>/dev/null; echo "*/$CHECK_INTERVAL * * * * $ALERT_SCRIPT") | crontab -

# تثبيت mailutils إذا لم يكن مثبتاً
if ! command -v mail &> /dev/null; then
    echo "📦 تثبيت mailutils لإرسال البريد الإلكتروني..."
    read -p "هل تريد تثبيت mailutils؟ (y/n): " install_mail
    if [ "$install_mail" = "y" ]; then
        sudo apt-get update
        sudo apt-get install -y mailutils
    else
        echo "⚠️  لن يتم إرسال تنبيهات البريد الإلكتروني"
    fi
fi

echo ""
echo "=========================================="
echo "✅ تم إعداد نظام التنبيهات بنجاح!"
echo "=========================================="
echo ""
echo "📧 البريد الإلكتروني: $ALERT_EMAIL"
echo "⏰ الفحص كل: $CHECK_INTERVAL دقائق"
echo "📝 السجل: /var/log/medmap-alerts.log"
echo "🔧 السكريبت: $ALERT_SCRIPT"
echo ""
echo "📊 الفحوصات المفعلة:"
echo "   ✅ حالة الحاويات"
echo "   ✅ استهلاك الذاكرة (> 90%)"
echo "   ✅ استهلاك المعالج (> 90%)"
echo "   ✅ مساحة التخزين (> 90%)"
echo "   ✅ حالة API"
echo "   ✅ حالة قاعدة البيانات"
echo "   ✅ الأخطاء في السجلات"
echo ""
echo "🔄 إعادة التشغيل التلقائي عند الفشل: مفعّل"
echo ""
echo "📝 لعرض السجل:"
echo "   sudo tail -f /var/log/medmap-alerts.log"
echo ""
echo "⚙️  لتعديل الإعدادات:"
echo "   sudo nano $ALERT_SCRIPT"
echo ""
echo "🗑️  لإلغاء التنبيهات:"
echo "   crontab -e  # ثم احذف السطر المتعلق بـ medmap-alert.sh"
echo ""

