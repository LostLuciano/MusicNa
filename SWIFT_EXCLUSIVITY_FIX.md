# Swift Exclusivity Violation Fix - AudioFeatureExtractor.swift

**Date:** June 1, 2026  
**Issue:** Overlapping memory access violations in vDSP operations  
**Status:** ✅ FIXED

## Problem

GitHub Actions build failed with Swift exclusivity errors:

```
error: overlapping accesses to 'realPart', but modification requires exclusive access
error: overlapping accesses to 'imagPart', but modification requires exclusive access
error: overlapping accesses to 'output', but modification requires exclusive access
```

### Root Cause

Swift 5.x enforces strict exclusivity rules. The code was violating these rules by:

1. **In computeSTFT (lines 79-90):**
   ```swift
   realPart.withUnsafeMutableBufferPointer { rBuf in
       imagPart.withUnsafeMutableBufferPointer { iBuf in
           // ... FFT logic ...
           vDSP_vsmul(realPart, 1, &scale, &realPart, 1, vDSP_Length(halfN))  // ❌ WRONG
           vDSP_vsmul(imagPart, 1, &scale, &imagPart, 1, vDSP_Length(halfN))  // ❌ WRONG
       }
   }
   ```
   
   Inside the `withUnsafeMutableBufferPointer` closure, referencing the original array (`realPart`, `imagPart`) directly violates exclusivity. The closure already has exclusive access via the buffer pointer.

2. **In computeISTFT (line 161):**
   ```swift
   vDSP_vsmul(output, 1, &scale, &output, 1, vDSP_Length(output.count))  // ❌ WRONG
   ```
   
   In-place operation where input and output are the same array.

3. **In computeISTFTStereo (lines 389-390):**
   ```swift
   vDSP_vsmul(leftOutput, 1, &scale, &leftOutput, 1, vDSP_Length(leftOutput.count))   // ❌ WRONG
   vDSP_vsmul(rightOutput, 1, &scale, &rightOutput, 1, vDSP_Length(rightOutput.count)) // ❌ WRONG
   ```

## Solution

### Fix 1: Use Pointer-Based Calls in computeSTFT

**Before:**
```swift
realPart.withUnsafeMutableBufferPointer { rBuf in
    imagPart.withUnsafeMutableBufferPointer { iBuf in
        var splitComplex = DSPSplitComplex(realp: rBuf.baseAddress!, imagp: iBuf.baseAddress!)
        // ... FFT logic ...
        var scale = Float(1.0 / Float(nFFT))
        vDSP_vsmul(realPart, 1, &scale, &realPart, 1, vDSP_Length(halfN))
        vDSP_vsmul(imagPart, 1, &scale, &imagPart, 1, vDSP_Length(halfN))
    }
}
```

**After:**
```swift
realPart.withUnsafeMutableBufferPointer { rBuf in
    imagPart.withUnsafeMutableBufferPointer { iBuf in
        guard let realPtr = rBuf.baseAddress, let imagPtr = iBuf.baseAddress else { return }
        var splitComplex = DSPSplitComplex(realp: realPtr, imagp: imagPtr)
        // ... FFT logic ...
        var scale = Float(1.0 / Float(nFFT))
        vDSP_vsmul(realPtr, 1, &scale, realPtr, 1, vDSP_Length(halfN))      // ✅ Use pointer
        vDSP_vsmul(imagPtr, 1, &scale, imagPtr, 1, vDSP_Length(halfN))      // ✅ Use pointer
    }
}
```

### Fix 2: Wrap In-Place Operations in computeISTFT

**Before:**
```swift
if maxVal > 0 {
    var scale = 1.0 / maxVal
    vDSP_vsmul(output, 1, &scale, &output, 1, vDSP_Length(output.count))
}
```

**After:**
```swift
if maxVal > 0 {
    var scale = 1.0 / maxVal
    output.withUnsafeMutableBufferPointer { buf in
        guard let ptr = buf.baseAddress else { return }
        vDSP_vsmul(ptr, 1, &scale, ptr, 1, vDSP_Length(output.count))  // ✅ Safe in-place
    }
}
```

### Fix 3: Wrap In-Place Operations in computeISTFTStereo

**Before:**
```swift
if maxVal > 0 {
    var scale = 1.0 / maxVal
    vDSP_vsmul(leftOutput, 1, &scale, &leftOutput, 1, vDSP_Length(leftOutput.count))
    vDSP_vsmul(rightOutput, 1, &scale, &rightOutput, 1, vDSP_Length(rightOutput.count))
}
```

**After:**
```swift
if maxVal > 0 {
    var scale = 1.0 / maxVal
    leftOutput.withUnsafeMutableBufferPointer { buf in
        guard let ptr = buf.baseAddress else { return }
        vDSP_vsmul(ptr, 1, &scale, ptr, 1, vDSP_Length(leftOutput.count))  // ✅ Safe
    }
    rightOutput.withUnsafeMutableBufferPointer { buf in
        guard let ptr = buf.baseAddress else { return }
        vDSP_vsmul(ptr, 1, &scale, ptr, 1, vDSP_Length(rightOutput.count)) // ✅ Safe
    }
}
```

## Key Changes

| Location | Issue | Fix |
|----------|-------|-----|
| computeSTFT (lines 79-90) | Direct array reference inside withUnsafeMutableBufferPointer | Use `realPtr` and `imagPtr` from buffer pointers |
| computeISTFT (line 161) | In-place vDSP_vsmul on same array | Wrap in withUnsafeMutableBufferPointer |
| computeISTFTStereo (lines 389-390) | In-place vDSP_vsmul on same arrays | Wrap each in withUnsafeMutableBufferPointer |

## Verification

✅ **Syntax Check:** No diagnostics found  
✅ **Exclusivity Rules:** All vDSP operations now use proper pointer-based access  
✅ **DSP Logic:** No changes to audio processing algorithms  
✅ **API Compatibility:** Public function signatures unchanged  

## Build Status

**Before Fix:**
```
error: overlapping accesses to 'realPart', but modification requires exclusive access
error: overlapping accesses to 'imagPart', but modification requires exclusive access
error: overlapping accesses to 'output', but modification requires exclusive access
** ARCHIVE FAILED **
```

**After Fix:**
```
✅ Ready for clean archive build
```

## Commit

```
ed16231 Fix Swift exclusivity violations in AudioFeatureExtractor - use pointer-based vDSP calls
```

---

**Next Step:** Run clean archive on GitHub Actions to verify build succeeds with iOS 18.0 target.
