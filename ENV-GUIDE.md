# راهنمای فایل‌های Environment

پروژه دارای چند فایل environment است که برای حالت‌های مختلف استفاده می‌شوند:

## فایل‌ها

### `.env` (فایل فعال)
فایلی که در حال حاضر استفاده می‌شود. این فایل در `.gitignore` است و commit نمی‌شود.

### `.env.example`
تمپلیت اصلی برای ایجاد `.env` جدید.

### `.env.local`
تنظیمات برای اجرای **بدون Docker** (local development)
- استفاده از SQLite یا PostgreSQL روی localhost
- برای استفاده: `cp .env.local .env`

### `.env.docker`
تنظیمات برای اجرای **با Docker Compose**
- استفاده از PostgreSQL سرویس Docker (hostname: `postgres`)
- برای استفاده: `cp .env.docker .env`

---

## نحوه استفاده

### برای Local Development (بدون Docker):

```bash
# کپی فایل local
cp .env.local .env

# ویرایش در صورت نیاز
nano .env

# اجرا
./start.sh
```

### برای Docker:

```bash
# فایل .env.docker به صورت خودکار استفاده می‌شود
docker compose up -d

# یا اگر می‌خواهید .env را هم استفاده کنید:
cp .env.docker .env
docker compose up -d
```

### برای Production Server:

```bash
# اسکریپت setup خودش .env می‌سازد
./setup-server.sh
```

---

## تفاوت‌های کلیدی

| مورد | `.env.local` | `.env.docker` |
|------|-------------|---------------|
| Database Host | `localhost` یا SQLite | `postgres` (Docker service) |
| استفاده | Local development | Docker Compose |
| PostgreSQL | باید نصب باشد | Docker خودش نصب می‌کند |

---

## نکات مهم

### ⚠️ هشدار امنیتی

1. **هرگز** فایل `.env` را commit نکنید
2. `SECRET_KEY` را در production حتماً تغییر دهید:
   ```bash
   python3 -c "import secrets; print(secrets.token_hex(32))"
   ```
3. پسورد دیتابیس را در production تغییر دهید

### 🔍 عیب‌یابی

**خطا: Connection refused (port 5432)**
- در حال اجرا با Docker هستید اما از `.env.local` استفاده می‌کنید
- حل: `cp .env.docker .env` و دوباره `docker compose up`

**خطا: no such table**
- دیتابیس SQLite خالی است
- حل: یک بار API را اجرا کنید تا جداول ساخته شوند

**خطا: Invalid SECRET_KEY**
- SECRET_KEY تنظیم نشده یا پیش‌فرض است
- حل: یک کلید جدید generate کنید

---

## مثال‌ها

### Local با SQLite:
```env
DATABASE_URL=sqlite:///./closefriend.db
```

### Local با PostgreSQL:
```env
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/closefriend
```

### Docker:
```env
DATABASE_URL=postgresql+psycopg://postgres:postgres@postgres:5432/closefriend
```

### Production:
```env
DATABASE_URL=postgresql+psycopg://user:secure_password@localhost:5432/closefriend
SECRET_KEY=generated_64_character_hex_string
ENVIRONMENT=prod
```

---

## Quick Reference

```bash
# Switch to local development
cp .env.local .env
./start.sh

# Switch to Docker
cp .env.docker .env
docker compose up -d

# Generate new secret key
python3 -c "import secrets; print(secrets.token_hex(32))"

# View current environment
cat .env | grep -v "^#"
```
