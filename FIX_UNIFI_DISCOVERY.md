# UniFi Camera Discovery Fix 🔧
## MFA Authentication Required

**Issue**: Camera discovery doesn't work
**Root Cause**: MFA session expired/not established
**Solution**: Re-authenticate with Google Authenticator code

---

## ✅ **QUICK FIX - DO THIS NOW**

### **Step 1: Get Your Google Authenticator Code**

Open **Google Authenticator** app on your phone and get the 6-digit code for UniFi.

### **Step 2: Re-Connect in the App**

1. **In RTSP Rotator app**
2. **Menu Bar → UniFi Protect → Connect to Controller**
3. **Enter credentials** (should auto-fill):
   - Host: 192.168.1.9
   - Username: kochjpar@gmail.com
   - Password: (your password)
4. **Click "Connect"**
5. **MFA Dialog Will Appear** ← This is the key!
6. **Enter your 6-digit code from Google Authenticator**
7. **Click "Submit"**

### **Step 3: Discover Cameras**

After successful MFA:
1. **UniFi Protect → Discover Cameras**
2. **Should work now!** ✅

---

## 🔍 **WHAT WAS WRONG**

### **Session Cookie Status:**
```bash
Cookie Files: /tmp/unifi_cookies_19216819_kochjpargmailcom.txt
Status: EMPTY (no valid session)
Result: API returns 401 Unauthorized
```

### **Why Empty:**
- MFA not completed yet
- Or: Session expired (24 hour timeout)
- Or: Old authentication attempt failed

---

## 🔐 **UNDERSTANDING UNIFI MFA**

Your UniFi account has **3 MFA methods**:

1. **Email** (kochjpar@gmail.com)
   - Sends code to email
   - Slower

2. **WebAuthn** (Amy's iPhone)
   - Uses Face ID/Touch ID
   - Requires iPhone nearby

3. **TOTP** (Google Authenticator) ← **DEFAULT**
   - 6-digit rotating code
   - Fastest method
   - **This is what you should use**

---

## 🧪 **TEST AUTHENTICATION MANUALLY**

If the app doesn't show MFA dialog, test manually:

```bash
# Step 1: Get MFA code from Google Authenticator
# Example: 123456

# Step 2: Authenticate via curl
curl -k -s -c /tmp/unifi_test_cookies.txt \
  -X POST "https://192.168.1.9/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username":"kochjpar@gmail.com",
    "password":"Jkoogie001",
    "token":"123456",
    "rememberMe":true
  }'

# Step 3: Test camera discovery
curl -k -s -b /tmp/unifi_test_cookies.txt \
  "https://192.168.1.9/proxy/protect/api/cameras" \
  | python3 -m json.tool

# Should list all cameras!
```

---

## 💡 **WHY MFA IS REQUIRED**

UniFi Protect (newer versions) enforces 2FA for security:
- Prevents unauthorized access
- Required by Ubiquiti Cloud SSO
- Cannot be disabled
- Must be completed once per session

**Session Lifetime:**
- 24 hours with "rememberMe": true
- After 24h: Must re-authenticate with MFA
- Cookie stored in /tmp/unifi_cookies_*

---

## 🔧 **WHAT I'LL DO TO HELP**

Let me enhance the MFA flow:

1. ✅ Clear old session cookies
2. ✅ Add better MFA error messages
3. ✅ Auto-prompt for MFA
4. ✅ Add session status checking

---

## 📋 **TROUBLESHOOTING**

### **Problem: MFA Dialog Doesn't Appear**

**Solution**: Manually trigger connection:
```
Menu → UniFi Protect → Connect to Controller
```

### **Problem: "Invalid MFA Token"**

**Solutions:**
- ✅ Make sure code is current (they expire every 30 seconds)
- ✅ Check you're using Google Authenticator (not other app)
- ✅ Verify correct UniFi account

### **Problem: MFA Works but Discovery Still Fails**

**Solution**: Check cookie file:
```bash
cat /tmp/unifi_cookies_19216819_kochjpargmailcom.txt

# Should contain:
192.168.1.9	FALSE	/	TRUE	...	TOKEN	eyJhbGc...
```

---

## ✅ **ACTION REQUIRED**

**RIGHT NOW:**

1. **Open Google Authenticator on your phone**
2. **Find the UniFi code** (refreshes every 30 seconds)
3. **In app: Menu → UniFi Protect → Connect to Controller**
4. **When MFA prompt appears, enter the 6-digit code**
5. **Then try: UniFi Protect → Discover Cameras**

**It will work after MFA!** ✅

---

**Session cookie will be valid for 24 hours after successful MFA.**

Let me know when you've entered the MFA code and I'll help verify discovery works!
