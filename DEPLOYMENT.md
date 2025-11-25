# 🚀 راهنمای سریع دیپلوی سرور

## نصب خودکار (یک دستوری)

### گام 1️⃣: اتصال به سرور

```bash
ssh your-user@your-server-ip
```

### گام 2️⃣: کلون پروژه

```bash
cd ~
git clone https://github.com/pouyamworld/closefriend.git
cd closefriend
```

### گام 3️⃣: اجرای اسکریپت نصب

```bash
./setup-server.sh
```

این اسکریپت به صورت خودکار:
- ✅ سیستم را آپدیت می‌کند
- ✅ Python 3.11 نصب می‌کند
- ✅ PostgreSQL نصب و پیکربندی می‌کند
- ✅ دیتابیس و کاربر می‌سازد
- ✅ محیط مجازی Python ایجاد می‌کند
- ✅ تمام dependency ها را نصب می‌کند
- ✅ فایل `.env` با تنظیمات امن می‌سازد
- ✅ سرویس systemd راه‌اندازی می‌کند
- ✅ Nginx پیکربندی می‌کند
- ✅ فایروال تنظیم می‌کند
- ✅ (اختیاری) SSL با Let's Encrypt

### گام 4️⃣: دسترسی به API

پس از نصب، API در آدرس زیر در دسترس است:

```
http://your-domain/
http://your-domain/swagger   (مستندات)
http://your-domain/redoc      (مستندات جایگزین)
```

---

## 🔄 به‌روزرسانی

برای به‌روزرسانی کد پس از تغییرات:

```bash
cd /var/www/closefriend
./update-server.sh
```

---

## ⚙️ مدیریت سرویس

### مشاهده وضعیت
```bash
sudo systemctl status closefriend
```

### ری‌استارت
```bash
sudo systemctl restart closefriend
```

### توقف
```bash
sudo systemctl stop closefriend
```

### شروع
```bash
sudo systemctl start closefriend
```

### مشاهده لاگ‌ها (زنده)
```bash
sudo journalctl -u closefriend -f
```

### مشاهده لاگ‌های خطا
```bash
sudo tail -f /var/log/closefriend/error.log
```

### مشاهده لاگ‌های دسترسی
```bash
sudo tail -f /var/log/closefriend/access.log
```

---

## 🔧 پیکربندی

### ویرایش تنظیمات

```bash
nano /var/www/closefriend/.env
```

پس از تغییر، حتماً سرویس را ری‌استارت کنید:

```bash
sudo systemctl restart closefriend
```

### اضافه کردن Google OAuth

```bash
nano /var/www/closefriend/.env
```

خط زیر را پیدا و مقدار را تنظیم کنید:
```
GOOGLE_CLIENT_ID=your-google-client-id
```

### اضافه کردن Telegram Bot

```bash
nano /var/www/closefriend/.env
```

```
TELEGRAM_BOT_TOKEN=your-bot-token
```

### تنظیم CORS برای فرانت‌اند

```
BACKEND_CORS_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
```

---

## 🗄️ مدیریت دیتابیس

### اتصال به PostgreSQL

```bash
sudo -u postgres psql closefriend
```

### بکاپ دیتابیس

```bash
sudo -u postgres pg_dump closefriend > backup_$(date +%Y%m%d).sql
```

### بازیابی از بکاپ

```bash
sudo -u postgres psql closefriend < backup_20251125.sql
```

### مشاهده اطلاعات دیتابیس

اطلاعات اتصال در فایل `.credentials` ذخیره شده:

```bash
cat /var/www/closefriend/.credentials
```

---

## 🔒 تنظیم SSL (HTTPS)

اگر در نصب اولیه SSL را تنظیم نکردید:

```bash
sudo certbot --nginx -d yourdomain.com
```

تمدید خودکار:
```bash
sudo certbot renew --dry-run
```

---

## 🐛 عیب‌یابی

### سرویس استارت نمی‌شود

1. چک کردن لاگ‌ها:
```bash
sudo journalctl -u closefriend -n 50
```

2. چک کردن فایل `.env`:
```bash
cat /var/www/closefriend/.env
```

3. تست دستی:
```bash
cd /var/www/closefriend
source .venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### خطای دیتابیس

چک کردن PostgreSQL:
```bash
sudo systemctl status postgresql
```

تست اتصال:
```bash
psql -h localhost -U closefriend_user -d closefriend
```

### Nginx خطا می‌دهد

تست کانفیگ:
```bash
sudo nginx -t
```

چک لاگ‌ها:
```bash
sudo tail -f /var/log/nginx/error.log
```

---

## 📊 مانیتورینگ

### استفاده از منابع

```bash
# CPU و Memory
htop

# فضای دیسک
df -h

# پورت‌های فعال
sudo netstat -tlnp | grep -E ':(80|443|8000|5432)'
```

### تعداد درخواست‌ها

```bash
sudo tail -n 1000 /var/log/closefriend/access.log | wc -l
```

---

## 🔐 امنیت

### تغییر پسورد دیتابیس

```bash
sudo -u postgres psql
```

```sql
ALTER USER closefriend_user WITH PASSWORD 'new-secure-password';
```

سپس `.env` را به‌روزرسانی کنید.

### تغییر SECRET_KEY

```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

خروجی را در `.env` قرار دهید:
```
SECRET_KEY=new-secret-key-here
```

---

## 📋 چک‌لیست پس از نصب

- [ ] API در مرورگر باز می‌شود
- [ ] Swagger UI کار می‌کند
- [ ] ثبت‌نام کاربر جدید موفق است
- [ ] لاگین کار می‌کند
- [ ] SSL نصب شده (برای production)
- [ ] فایروال فعال است
- [ ] بکاپ خودکار تنظیم شده
- [ ] مانیتورینگ فعال است

---

## ☁️ سرورهای پیشنهادی

### DigitalOcean
```bash
# ایجاد Droplet با Ubuntu 22.04
# حداقل: 1GB RAM، 1 vCPU
```

### AWS EC2
```bash
# t2.micro برای شروع کافی است
# Ubuntu 22.04 LTS
```

### Linode
```bash
# Nanode 1GB
```

### Hetzner
```bash
# CX11 (2GB RAM)
```

---

## 💡 نکات مهم

1. **بکاپ**: حتماً از دیتابیس به صورت روزانه بکاپ بگیرید
2. **لاگ‌ها**: به صورت دوره‌ای لاگ‌ها را چک کنید
3. **به‌روزرسانی**: سیستم و dependency ها را به‌روز نگه دارید
4. **مانیتورینگ**: از ابزارهایی مثل Prometheus یا Grafana استفاده کنید
5. **Scaling**: برای ترافیک بالا، تعداد workers را افزایش دهید

---

## 📞 پشتیبانی

در صورت بروز مشکل، لاگ‌های زیر را چک کنید:

1. `/var/log/closefriend/error.log`
2. `sudo journalctl -u closefriend -n 100`
3. `/var/log/nginx/error.log`
4. `sudo -u postgres psql -c "\l"` (چک دیتابیس)
