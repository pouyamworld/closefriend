# راهنمای تنظیم بکاپ خودکار روزانه

## روش 1: استفاده از Cron (پیشنهادی)

### 1. کپی اسکریپت بکاپ

```bash
sudo cp /var/www/closefriend/backup-db.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/backup-db.sh
```

### 2. افزودن به crontab

```bash
sudo crontab -e
```

اضافه کردن خط زیر (بکاپ روزانه در ساعت 2 صبح):

```
0 2 * * * /usr/local/bin/backup-db.sh >> /var/log/closefriend-backup.log 2>&1
```

### 3. بررسی cron jobs

```bash
sudo crontab -l
```

---

## روش 2: استفاده از Systemd Timer

### 1. ایجاد سرویس

```bash
sudo nano /etc/systemd/system/closefriend-backup.service
```

محتوا:
```ini
[Unit]
Description=CloseFriend Database Backup
After=postgresql.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup-db.sh
User=postgres
```

### 2. ایجاد تایمر

```bash
sudo nano /etc/systemd/system/closefriend-backup.timer
```

محتوا:
```ini
[Unit]
Description=Daily CloseFriend Database Backup
Requires=closefriend-backup.service

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target
```

### 3. فعال‌سازی تایمر

```bash
sudo systemctl daemon-reload
sudo systemctl enable closefriend-backup.timer
sudo systemctl start closefriend-backup.timer
```

### 4. بررسی وضعیت

```bash
sudo systemctl status closefriend-backup.timer
sudo systemctl list-timers
```

---

## بازیابی از بکاپ

### مشاهده بکاپ‌ها

```bash
ls -lh /var/backups/closefriend/
```

### بازیابی

```bash
# استخراج فایل فشرده
gunzip /var/backups/closefriend/closefriend_20251125_020000.sql.gz

# بازیابی به دیتابیس
sudo -u postgres psql closefriend < /var/backups/closefriend/closefriend_20251125_020000.sql
```

---

## بکاپ به فضای ابری (اختیاری)

### AWS S3

نصب AWS CLI:
```bash
sudo apt install awscli
aws configure
```

اضافه به اسکریپت بکاپ:
```bash
aws s3 cp $BACKUP_FILE.gz s3://your-bucket/backups/
```

### Google Cloud Storage

```bash
gsutil cp $BACKUP_FILE.gz gs://your-bucket/backups/
```

---

## تست بکاپ

اجرای دستی:
```bash
sudo /usr/local/bin/backup-db.sh
```

بررسی نتیجه:
```bash
ls -lh /var/backups/closefriend/
```
