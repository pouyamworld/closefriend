from datetime import datetime

# In production, replace with SMTP or third-party provider

def send_verification_code(email: str, code: str) -> None:
    # For dev/demo: print to console
    print(f"[EmailService] {datetime.utcnow().isoformat()} Send code {code} to {email}")
