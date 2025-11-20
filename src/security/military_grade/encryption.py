from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import base64
import os
from typing import Any

class MilitaryGradeEncryption:
    def __init__(self, master_key: str):
        self.master_key = master_key
        self.kdf = PBKDF2HMAC(
            algorithm=hashes.SHA512(),
            length=32,
            salt=os.urandom(16),
            iterations=1000000,  # High iteration count for security
        )
        
    def encrypt_data(self, data: Any) -> str:
        """Encrypt data with military-grade encryption"""
        
        # Generate key from master key
        key = base64.urlsafe_b64encode(
            self.kdf.derive(self.master_key.encode())
        )
        
        fernet = Fernet(key)
        
        if isinstance(data, str):
            encrypted_data = fernet.encrypt(data.encode())
        else:
            encrypted_data = fernet.encrypt(str(data).encode())
            
        return base64.urlsafe_b64encode(encrypted_data).decode()
    
    def decrypt_data(self, encrypted_data: str) -> Any:
        """Decrypt military-grade encrypted data"""
        
        encrypted_data = base64.urlsafe_b64decode(encrypted_data.encode())
        
        key = base64.urlsafe_b64encode(
            self.kdf.derive(self.master_key.encode())
        )
        
        fernet = Fernet(key)
        decrypted_data = fernet.decrypt(encrypted_data)
        
        return decrypted_data.decode()
