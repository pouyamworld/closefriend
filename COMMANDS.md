# 📚 دستورات سریع سرور

## 🚀 نصب اولیه

```bash
./setup-server.sh
```

---

## 🔄 به‌روزرسانی

```bash
./update-server.sh
```

---

## 🎛️ مدیریت سرویس

### منوی تعاملی
```bash
./manage-server.sh
```

### دستورات مستقیم

**مشاهده وضعیت:**
```bash
sudo systemctl status closefriend
```

**ری‌استارت:**
```bash
sudo systemctl restart closefriend
```

**توقف:**
```bash
sudo systemctl stop closefriend
```

**شروع:**
```bash
sudo systemctl start closefriend
```

---

## 📋 لاگ‌ها

**لاگ زنده:**
```bash
sudo journalctl -u closefriend -f
```

**50 خط آخر:**
```bash
sudo journalctl -u closefriend -n 50
```

**لاگ خطا:**
```bash
sudo tail -f /var/log/closefriend/error.log
```

**لاگ دسترسی:**
```bash
sudo tail -f /var/log/closefriend/access.log
```

---

## 🗄️ دیتابیس

**بکاپ:**
```bash
./backup-db.sh
```

**اتصال به دیتابیس:**
```bash
sudo -u postgres psql closefriend
```

**مشاهده اطلاعات:**
```bash
cat /var/www/closefriend/.credentials
```

---

## ⚙️ پیکربندی

**ویرایش تنظیمات:**
```bash
nano /var/www/closefriend/.env
sudo systemctl restart closefriend
```

**تست تنظیمات:**
```bash
cd /var/www/closefriend
source .venv/bin/activate
python -c "from app.config import get_settings; s=get_settings(); print(f'DB: {s.DATABASE_URL}')"
```

---

## 🌐 Nginx

**تست کانفیگ:**
```bash
sudo nginx -t
```

**ری‌استارت:**
```bash
sudo systemctl restart nginx
```

**لاگ خطا:**
```bash
sudo tail -f /var/log/nginx/error.log
```

---

## 🔍 عیب‌یابی

**چک API:**
```bash
curl http://localhost:8000/openapi.json
```

**چک پورت‌ها:**
```bash
sudo netstat -tlnp | grep -E ':(80|443|8000|5432)'
```

**استفاده از منابع:**
```bash
htop
```

**فضای دیسک:**
```bash
df -h
```

---

## 🔒 امنیت

**بررسی فایروال:**
```bash
sudo ufw status
```

**مشاهده اتصالات:**
```bash
sudo netstat -an | grep :8000
```

---

## 📊 مانیتورینگ

**تعداد درخواست‌ها (24 ساعت گذشته):**
```bash
sudo journalctl -u closefriend --since "24 hours ago" | grep "POST\|GET" | wc -l
```

**میانگین زمان پاسخ:**
```bash
sudo tail -1000 /var/log/closefriend/access.log | awk '{print $(NF-1)}' | awk '{s+=$1; c++} END {print s/c " ms"}'
```

---

## 🎯 دسترسی سریع

| آدرس | توضیحات |
|------|---------|
| `http://your-domain/` | API اصلی |
| `http://your-domain/swagger` | مستندات Swagger |
| `http://your-domain/redoc` | مستندات ReDoc |
| `http://your-domain/openapi.json` | OpenAPI Spec |

---

## 📞 کمک

**لاگ‌های کامل برای عیب‌یابی:**
```bash
sudo journalctl -u closefriend -n 100 --no-pager > debug.log
sudo tail -100 /var/log/closefriend/error.log >> debug.log
sudo nginx -t >> debug.log 2>&1
cat debug.log
```
