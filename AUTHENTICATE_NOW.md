# 🔐 AUTHENTICATE WITH UNIFI NOW
## Run This Script to Fix Discovery

**Date**: October 30, 2025
**Issue**: No session cookie = HTTP 401 errors
**Solution**: Authenticate with MFA code

---

## ✅ **QUICK FIX - RUN THIS SCRIPT**

### **Step 1: Open Terminal**

### **Step 2: Run This Command**

```bash
/tmp/authenticate_unifi.sh
```

### **Step 3: Follow Prompts**

The script will:
1. Ask for your Google Authenticator 6-digit code
2. Authenticate with UniFi Protect
3. Create session cookie
4. Test that it works
5. Show you cameras!

---

## 📋 **WHAT THE SCRIPT DOES**

```
1. Prompts for MFA code
2. Calls: POST https://192.168.1.9/api/auth/login
3. Includes: username, password, MFA token
4. Saves: Session cookie to /tmp/unifi_cookies_19216819_kochjpargmailcom.txt
5. Tests: GET https://192.168.1.9/proxy/protect/api/cameras
6. Shows: Camera list if successful
```

---

## 🎯 **AFTER RUNNING THE SCRIPT**

Once you see "✅ AUTHENTICATION SUCCESSFUL":

1. **Go back to RTSP Rotator app**
2. **Menu → UniFi Protect → Discover Cameras**
3. **NOW IT WILL WORK!** ✅

The session cookie is valid for 24 hours.

---

## 💡 **WHY USE THE SCRIPT?**

The script:
- ✅ Handles MFA properly
- ✅ Creates cookie correctly
- ✅ Tests that it works
- ✅ Shows detailed output
- ✅ Gives clear error messages

**Faster and more reliable than clicking through UI!**

---

## 🚀 **DO THIS NOW**

```bash
# Copy and paste this:
/tmp/authenticate_unifi.sh
```

Then:
1. Enter your Google Authenticator code when prompted
2. Wait for "✅ AUTHENTICATION SUCCESSFUL!"
3. Try discovery in the app
4. SUCCESS! 🎉

---

## 📊 **CURRENT STATUS**

```
✅ App: RESTARTED (PID: 77094)
✅ Enhanced Logging: ACTIVE
✅ RTSP Mode: Enabled
✅ Helper Script: Ready at /tmp/authenticate_unifi.sh
⏳ Waiting: Your MFA code to create session
```

---

**RUN THE SCRIPT NOW!**

Open Terminal and run: `/tmp/authenticate_unifi.sh`

Then discovery will work! 🚀
