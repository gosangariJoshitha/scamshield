import sys
import os
backend_dir = os.path.dirname(os.path.abspath(__file__))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

import database, models, auth

def get_latest_login_code():
    db = database.SessionLocal()
    try:
        ch = db.query(models.AuthChallenge).filter(
            models.AuthChallenge.purpose == 'LOGIN',
            models.AuthChallenge.consumed_at == None
        ).order_by(models.AuthChallenge.id.desc()).first()
        if not ch:
            return None
        for i in range(1000000):
            c_str = f"{i:06d}"
            if auth._hash_verification_code(c_str) == ch.code_hash:
                return c_str
        return None
    finally:
        db.close()

if __name__ == "__main__":
    code = get_latest_login_code()
    print("LATEST_LOGIN_CODE:", code)
