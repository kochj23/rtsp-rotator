# Google Home Removal Log

**Date:** December 5, 2025
**Reason:** Functionality never worked, 800+ lines of dead code
**Author:** Jordan Koch

## Files Deleted
1. ✅ RTSP Rotator/RTSPGoogleHomeAdapter.h (111 lines)
2. ✅ RTSP Rotator/RTSPGoogleHomeAdapter.m (692 lines)

**Total Deleted:** 803 lines

## Files Modified

### AppDelegate.m
**Removed:**
- Import statement for RTSPGoogleHomeAdapter.h (line 43)
- 7 notification observers for Google Home (lines 510-516)
- 7 handler methods:
  - `handleAuthenticateGoogleHome:` (~30 lines)
  - `handleDiscoverGoogleHomeCameras:` (~30 lines)
  - `handleManageGoogleHomeCameras:` (~5 lines)
  - `handleRefreshGoogleHomeStreams:` (~10 lines)
  - `handleAddGoogleHomeCamera:` (~5 lines)
  - `handleTestGoogleHomeCameras:` (~10 lines)
  - `handleShowGoogleHomeSettings:` (~5 lines)
- `showGoogleHomeCredentialsDialog` method (~80 lines)
- All Google Home adapter interactions

**Estimated Removal:** ~175 lines from AppDelegate.m

### RTSPMenuBarController.m
**Removed:**
- Google Home menu section
- Google Home menu items (7 items)
- Google Home notification posts

**Estimated Removal:** ~50 lines

### RTSPPreferencesController.m
**Removed:**
- Google Home tab
- Google Home authentication UI
- OAuth configuration fields

**Estimated Removal:** ~100 lines

### RTSPCameraTypeManager.h/m
**Removed:**
- GoogleHome camera type enum value
- Google Home specific methods
- Google Home adapter integration

**Estimated Removal:** ~50 lines

## Documentation Updates

### README.md
**Removed:**
- Google Home integration section
- Google Home setup instructions
- Google Home troubleshooting
- Google Home examples

**Estimated Removal:** ~80 lines

### Other Docs
- FEATURES.md - Remove Google Home features
- CHANGELOG.md - Note removal
- INSTALL.md - Remove Google Home setup

## Total Impact

**Lines Removed:** ~1,258 lines
**Files Deleted:** 2
**Files Modified:** 8+
**Build Size Reduction:** ~150KB
**Complexity Reduction:** Significant

## Migration Notes

**For Users:**
- Google Home functionality removed in v2.3
- Use UniFi Protect or standard RTSP cameras instead
- No data migration needed (was non-functional)

## Verification Checklist

- [x] Adapter files deleted
- [ ] All imports removed
- [ ] All notification observers removed
- [ ] All handler methods removed
- [ ] All menu items removed
- [ ] All preferences UI removed
- [ ] All enum values removed
- [ ] Documentation updated
- [ ] Build successful
- [ ] No compiler warnings related to Google Home

---

**Status:** In Progress - Systematic removal underway
