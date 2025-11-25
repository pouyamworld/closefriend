# 🔒 راهنمای امنیتی Docker

## ⚠️ مشکل کریپتو ماینر

اگر استفاده CPU بالای 700% مشاهده کردید، احتمالاً کانتینر شما به کریپتو ماینر آلوده شده است.

---

## ✅ اقدامات فوری

### 1. توقف فوری کانتینرها

```bash
docker compose down
docker stop $(docker ps -aq)
```

### 2. بررسی استفاده از منابع

```bash
./docker-monitor.sh
```

یا:

```bash
docker stats
```

### 3. بررسی پروسه‌های مشکوک

```bash
docker top closefriend-app
docker exec closefriend-app ps aux
```

### 4. بررسی لاگ‌ها

```bash
docker logs closefriend-app --tail 100
```

### 5. پاک‌سازی کامل

```bash
# حذف تمام کانتینرها
docker compose down

# حذف ایمیج‌ها
docker rmi $(docker images -q closefriend*)

# پاک‌سازی سیستم
docker system prune -a --volumes
```

---

## 🛡️ اصلاحات امنیتی اعمال شده

### Dockerfile

✅ **اجرا با کاربر غیر root**
- کانتینر به عنوان `appuser` اجرا می‌شود نه root
- جلوگیری از دسترسی‌های بالا

✅ **حذف ابزارهای خطرناک**
- `curl` و `wget` حذف شدند
- نمی‌توان اسکریپت مخرب دانلود کرد

✅ **نصب محدود پکیج‌ها**
- فقط `libpq5` برای PostgreSQL
- بدون ابزارهای اضافی

✅ **Health Check**
- مانیتورینگ سلامت کانتینر

### docker-compose.yml

✅ **محدودیت منابع (CRITICAL)**
```yaml
limits:
  cpus: '0.5'      # حداکثر 50% یک هسته
  memory: 512M     # حداکثر 512MB
```

✅ **Filesystem فقط خواندنی**
```yaml
read_only: true
tmpfs:
  - /tmp
```

✅ **حذف تمام Capabilities**
```yaml
cap_drop:
  - ALL
cap_add:
  - NET_BIND_SERVICE  # فقط برای پورت
```

✅ **No New Privileges**
```yaml
security_opt:
  - no-new-privileges:true
```

✅ **شبکه ایزوله شده**
```yaml
networks:
  closefriend-network:
    driver: bridge
```

✅ **کاربر غیر root**
```yaml
user: "1000:1000"
```

---

## 🔍 چگونه بفهمیم کریپتو ماینر داریم؟

### علائم:

1. **CPU بالای 200%+** - استفاده غیرعادی از پردازنده
2. **پروسه‌های مشکوک** - نام‌هایی مثل: `xmrig`, `minerd`, `cryptonight`
3. **اتصالات شبکه مشکوک** - اتصال به پورت‌های mining pools (معمولاً 3333, 4444, 5555)
4. **مصرف RAM بالا** - استفاده بیش از حد از حافظه
5. **دمای بالای سرور** - گرم شدن غیرعادی

### بررسی:

```bash
# بررسی CPU
docker stats

# بررسی پروسه‌ها
docker exec closefriend-app ps aux | grep -E "xmrig|minerd|crypto"

# بررسی اتصالات شبکه
docker exec closefriend-app netstat -tuln
```

---

## 🚀 راه‌اندازی امن

### 1. پاک‌سازی کامل

```bash
cd ~/closefriend

# توقف همه چیز
docker compose down -v

# حذف ایمیج‌ها
docker rmi -f $(docker images -q)

# پاک‌سازی سیستم
docker system prune -a --volumes --force
```

### 2. دریافت آخرین نسخه امن

```bash
git pull origin main
```

### 3. ساخت مجدد با تنظیمات امن

```bash
# ساخت بدون کش
docker compose build --no-cache

# اجرا
docker compose up -d
```

### 4. بررسی وضعیت

```bash
# چک منابع
./docker-monitor.sh

# چک لاگ
docker compose logs -f
```

---

## 📊 مانیتورینگ مداوم

### اسکریپت خودکار

```bash
# اجرای مانیتور هر 5 دقیقه
watch -n 300 ./docker-monitor.sh
```

### یا با cron:

```bash
crontab -e
```

اضافه کنید:
```
*/5 * * * * /path/to/closefriend/docker-monitor.sh >> /var/log/docker-monitor.log 2>&1
```

---

## 🔐 بهترین روش‌های امنیتی

### 1. استفاده از Docker بدون root (Rootless)

```bash
# نصب Docker rootless
curl -fsSL https://get.docker.com/rootless | sh
```

### 2. اسکن امنیتی ایمیج

```bash
# نصب Trivy
sudo apt-get install wget
wget https://github.com/aquasecurity/trivy/releases/download/v0.48.0/trivy_0.48.0_Linux-64bit.deb
sudo dpkg -i trivy_0.48.0_Linux-64bit.deb

# اسکن ایمیج
trivy image closefriend-app
```

### 3. محدودیت شبکه

در `docker-compose.yml`:

```yaml
# برای app که فقط به postgres نیاز دارد
networks:
  closefriend-network:
    driver: bridge
    internal: true  # بدون دسترسی به اینترنت
```

⚠️ **توجه:** با `internal: true` کانتینر نمی‌تواند به اینترنت متصل شود.

### 4. به‌روزرسانی منظم

```bash
# هر هفته
docker compose pull
docker compose up -d --build
```

---

## ⚡️ توصیه نهایی

**برای Production از Docker استفاده نکنید!**

بهترین روش برای production:

```bash
# استفاده از اسکریپت نصب مستقیم
./setup-server.sh
```

مزایا:
- ✅ بدون overhead داکر
- ✅ مانیتورینگ آسان‌تر
- ✅ امنیت بیشتر
- ✅ Performance بهتر
- ✅ استفاده از منابع کمتر

---

## 🆘 در صورت آلودگی فعلی

### گام 1: قطع اتصال

```bash
# قطع اتصال شبکه کانتینر
docker network disconnect bridge closefriend-app
```

### گام 2: استخراج اطلاعات

```bash
# ذخیره لاگ‌ها برای بررسی
docker logs closefriend-app > infected-logs.txt

# ذخیره لیست پروسه‌ها
docker exec closefriend-app ps aux > infected-processes.txt

# ذخیره اتصالات شبکه
docker exec closefriend-app netstat -tuln > infected-network.txt
```

### گام 3: بکاپ دیتابیس

```bash
docker exec closefriend-postgres pg_dump -U postgres closefriend > backup.sql
```

### گام 4: حذف کامل و نصب مجدد

```bash
# حذف همه چیز
docker compose down -v
docker system prune -a --volumes --force

# نصب امن با اسکریپت
./setup-server.sh
```

### گام 5: بازیابی دیتا

```bash
# بازگردانی دیتابیس
sudo -u postgres psql closefriend < backup.sql
```

---

## 📞 چک‌لیست امنیتی

قبل از deploy:

- [ ] Dockerfile از user غیر root استفاده می‌کند
- [ ] Resource limits تنظیم شده (CPU < 1 core)
- [ ] Read-only filesystem فعال است
- [ ] Capabilities به حداقل رسیده
- [ ] No new privileges فعال است
- [ ] Health check تعریف شده
- [ ] Network isolated است
- [ ] .dockerignore شامل فایل‌های حساس است
- [ ] مانیتورینگ فعال است
- [ ] Logs بررسی می‌شود

---

## 🎯 خلاصه

1. **فوری**: توقف کانتینرها و بررسی با `docker-monitor.sh`
2. **کوتاه‌مدت**: rebuild با Dockerfile امن
3. **بلندمدت**: استفاده از `setup-server.sh` بدون Docker
