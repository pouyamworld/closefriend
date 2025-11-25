# عیب‌یابی نصب (Troubleshooting)

## ⚡️ تست سریع

قبل از هر کاری، اسکریپت تست را اجرا کنید:

```bash
./verify-setup.sh
```

این اسکریپت تمام مشکلات احتمالی را شناسایی می‌کند.

---

## خطاهای رایج و راه‌حل

### 0. خطای externally-managed-environment (Ubuntu 24.04)

**علت:** Ubuntu 24.04 از نصب مستقیم پکیج‌های Python جلوگیری می‌کند.

**راه‌حل:** اسکریپت به‌روزرسانی شده باید از `.venv/bin/pip` استفاده کند.

اگر همچنان خطا دارید:
```bash
cd /var/www/closefriend
source .venv/bin/activate
.venv/bin/pip install -r requirements.txt
```

---

### 1. خطای Python 3.11 not found

**علت:** Ubuntu 24.04 به صورت پیش‌فرض Python 3.12 دارد.

**راه‌حل:** اسکریپت به‌روزرسانی شده به صورت خودکار نسخه موجود را تشخیص می‌دهد.

اگر همچنان خطا دارید:
```bash
git pull  # دریافت آخرین نسخه
./setup-server.sh
```

---

### 2. خطای apt-get install

**علت:** مشکل در مخزن‌های apt یا اتصال اینترنت.

**راه‌حل:**
```bash
sudo apt-get update
sudo apt-get install -f  # تعمیر وابستگی‌های شکسته
./setup-server.sh
```

---

### 3. خطای PostgreSQL connection

**علت:** PostgreSQL شروع نشده یا پورت اشغال است.

**راه‌حل:**
```bash
sudo systemctl status postgresql
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

---

### 4. خطای Permission Denied

**علت:** اجرا با حساب root یا عدم دسترسی sudo.

**راه‌حل:**
```bash
# اجرا با کاربر عادی که دسترسی sudo دارد
chmod +x setup-server.sh
./setup-server.sh  # نه sudo ./setup-server.sh
```

---

### 5. خطای pip install

**علت:** مشکل در نصب پکیج‌های Python.

**راه‌حل:**
```bash
cd /var/www/closefriend
source .venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt -v  # نمایش جزئیات
```

---

### 6. خطای Database already exists

**علت:** دیتابیس از قبل وجود دارد (نصب قبلی).

**راه‌حل:**
این خطا نیست، اسکریپت از دیتابیس موجود استفاده می‌کند.

برای حذف و نصب مجدد:
```bash
sudo -u postgres psql -c "DROP DATABASE closefriend;"
sudo -u postgres psql -c "DROP USER closefriend_user;"
./setup-server.sh
```

---

### 7. سرویس start نمی‌شود

**راه‌حل:**
```bash
# بررسی لاگ
sudo journalctl -u closefriend -n 50

# تست دستی
cd /var/www/closefriend
source .venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

---

### 8. Nginx خطای 502 می‌دهد

**علت:** سرویس closefriend در حال اجرا نیست.

**راه‌حل:**
```bash
sudo systemctl status closefriend
sudo systemctl start closefriend
```

---

### 9. فایروال دسترسی را مسدود می‌کند

**راه‌حل:**
```bash
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw reload
```

---

### 10. خطای bcrypt/passlib

**علت:** بسته‌های C برای bcrypt نصب نشده.

**راه‌حل:**
```bash
sudo apt-get install build-essential libpq-dev python3-dev
cd /var/www/closefriend
source .venv/bin/activate
pip install --force-reinstall bcrypt passlib
```

---

## نصب دستی (اگر اسکریپت کار نکرد)

### گام 1: نصب Dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
    python3 python3-venv python3-pip \
    postgresql postgresql-contrib \
    nginx git curl build-essential libpq-dev
```

### گام 2: PostgreSQL

```bash
sudo systemctl start postgresql
sudo systemctl enable postgresql

sudo -u postgres psql << EOF
CREATE DATABASE closefriend;
CREATE USER closefriend_user WITH PASSWORD 'your-password';
GRANT ALL PRIVILEGES ON DATABASE closefriend TO closefriend_user;
ALTER DATABASE closefriend OWNER TO closefriend_user;
EOF
```

### گام 3: Application

```bash
sudo mkdir -p /var/www/closefriend
sudo chown $USER:$USER /var/www/closefriend
cd /var/www/closefriend

# کپی فایل‌های پروژه یا clone از git
git clone https://github.com/pouyamworld/closefriend.git .

python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### گام 4: Configuration

```bash
cat > .env << EOF
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
DATABASE_URL=postgresql+psycopg://closefriend_user:your-password@localhost:5432/closefriend
ENVIRONMENT=prod
ACCESS_TOKEN_EXPIRE_MINUTES=60
BACKEND_CORS_ORIGINS=
EOF
```

### گام 5: Systemd Service

```bash
sudo nano /etc/systemd/system/closefriend.service
```

محتوا را از فایل `setup-server.sh` کپی کنید.

```bash
sudo systemctl daemon-reload
sudo systemctl enable closefriend
sudo systemctl start closefriend
```

### گام 6: Nginx

```bash
sudo nano /etc/nginx/sites-available/closefriend
```

محتوا را از فایل `setup-server.sh` کپی کنید.

```bash
sudo ln -s /etc/nginx/sites-available/closefriend /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

---

## چک کردن وضعیت

```bash
# سرویس
sudo systemctl status closefriend

# لاگ
sudo journalctl -u closefriend -f

# API
curl http://localhost:8000/openapi.json

# Nginx
sudo nginx -t
sudo systemctl status nginx
```

---

## حذف کامل (برای نصب مجدد)

```bash
# توقف سرویس‌ها
sudo systemctl stop closefriend
sudo systemctl disable closefriend

# حذف فایل‌ها
sudo rm /etc/systemd/system/closefriend.service
sudo rm /etc/nginx/sites-enabled/closefriend
sudo rm /etc/nginx/sites-available/closefriend
sudo rm -rf /var/www/closefriend
sudo rm -rf /var/log/closefriend

# حذف دیتابیس
sudo -u postgres psql -c "DROP DATABASE IF EXISTS closefriend;"
sudo -u postgres psql -c "DROP USER IF EXISTS closefriend_user;"

# Reload
sudo systemctl daemon-reload
sudo systemctl reload nginx
```

---

## دریافت کمک

اگر با مشکلی مواجه شدید که در اینجا راه‌حل نیست:

1. لاگ‌ها را بررسی کنید:
```bash
sudo journalctl -u closefriend -n 100 > error.log
cat error.log
```

2. تست اتصال دیتابیس:
```bash
psql -h localhost -U closefriend_user -d closefriend
```

3. چک کردن پورت‌ها:
```bash
sudo netstat -tlnp | grep -E ':(80|443|8000|5432)'
```
