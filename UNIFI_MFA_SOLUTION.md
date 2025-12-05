# UniFi Camera Discovery - MFA Required! 🔐
## Why Discovery Doesn't Work + How to Fix It

**Date**: October 30, 2025
**Issue**: Camera discovery fails
**Root Cause**: UniFi Protect requires MFA (Multi-Factor Authentication)

---

## 🚨 **THE PROBLEM**

### **What's Happening:**
```
You: "Discovery doesn't seem to work anymore"

API Response:
{
  "required": "2fa",
  "message": "MFA token required to authenticate to SSO"
}

Your Account Has:
✅ Email MFA
✅ WebAuthn (Amy's iPhone)
✅ TOTP (Google Authenticator) ← DEFAULT
```

**UniFi Protect REQUIRES a 6-digit code from your Google Authenticator app!**

---

## ✅ **THE SOLUTION**

### **Step 1: Connect with MFA**

In the app (it should prompt you):

1. **Menu Bar → UniFi Protect → Connect to Controller**
2. Enter credentials:
   - Host: 192.168.1.9
   - Username: kochjpar@gmail.com
   - Password: Jkoogie001
3. **Click Connect**
4. **MFA Dialog Will Appear** (enter 6-digit code from Google Authenticator)
5. **After MFA Success**: Session cookie saved
6. **Then Discovery Will Work!**

---

## 🔧 **MANUAL FIX (If App Doesn't Prompt)**

### **Option 1: Authenticate with MFA via Terminal**

```bash
# Get your 6-digit Google Authenticator code (e.g., 123456)
MFA_CODE="123456"  # Replace with your actual code

# Authenticate with MFA
curl -k -s -c /tmp/unifi_session.txt -X POST \
  "https://192.168.1.9/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username":"kochjpar@gmail.com",
    "password":"Jkoogie001",
    "token":"'$MFA_CODE'",
    "rememberMe":true
  }'

# Should return success and save session cookie
```

### **Option 2: Use UniFi Protect Web UI**

If curl method is complex:

1. Open browser: https://192.168.1.9
2. Login with MFA
3. Session established
4. Then try discovery in app again

---

## 🔍 **TECHNICAL DETAILS**

### **Why It Requires MFA:**

UniFi Protect uses SSO (Single Sign-On) with mandatory 2FA:
```
Login Flow:
1. POST /api/auth/login with username/password
2. Response: "2fa required" + mfaCookie
3. Get 6-digit code from Google Authenticator
4. POST /api/auth/login again with token
5. Response: Success + session cookie
6. Cookie used for all subsequent API calls
```

### **Session Cookie:**
```bash
File: /tmp/unifi_cookies_1921681<parameter>_kochjpargmailcom.txt
Format: Netscape cookie format
Contains: SESSION=xxx, TOKEN=xxx
Lifetime: ~24 hours
```

---

## 🛠️ **WHAT I'LL FIX**

The app SHOULD prompt for MFA automatically, but let me enhance it:

1. ✅ **Better MFA prompt handling**
2. ✅ **Clear error messages**
3. ✅ **Session persistence**
4. ✅ **Automatic retry with MFA**

Let me update the code now!

---

**GET YOUR GOOGLE AUTHENTICATOR CODE READY!**

I'll trigger the MFA flow and you'll need to enter the 6-digit code.
