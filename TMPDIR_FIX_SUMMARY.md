# TMPDIR Unbound Variable Fix

## Problem
The pipeline was failing with the error: `.command.sh: line 5: TMPDIR: unbound variable`

This occurs when processes try to use the `$TMPDIR` environment variable but it's not set in the execution environment.

## Solution Applied

### 1. Global Fix in Base Configuration
Added a `beforeScript` directive to `conf/base.config` that initializes `TMPDIR` for all processes:

```groovy
// Initialize TMPDIR if not set to prevent unbound variable errors
beforeScript = '''
if [ -z "${TMPDIR:-}" ]; then
    export TMPDIR=$(mktemp -d)
fi
'''
```

This ensures that every process has a valid `TMPDIR` set before execution.

### 2. Process-Specific Fixes
Added explicit TMPDIR initialization in processes that specifically use it:

#### modules/local/shovill.nf
- Added TMPDIR check and initialization before shovill commands
- Applied to both downsampling and non-downsampling code paths

#### modules/local/snippy.nf  
- Added TMPDIR check and initialization before snippy commands
- Applied to both FASTQ input and FASTA input code paths

## Files Modified
1. `conf/base.config` - Global TMPDIR initialization
2. `modules/local/shovill.nf` - Process-specific TMPDIR handling
3. `modules/local/snippy.nf` - Process-specific TMPDIR handling

## How It Works
The fix uses a safe bash pattern:
```bash
if [ -z "${TMPDIR:-}" ]; then
    export TMPDIR=$(mktemp -d)
fi
```

This:
- Checks if TMPDIR is unset or empty using `${TMPDIR:-}`
- Creates a temporary directory using `mktemp -d` if needed
- Exports it as TMPDIR for use by the process

## Result
- Eliminates "unbound variable" errors for TMPDIR
- Provides a safe fallback temporary directory
- Maintains compatibility with systems that already have TMPDIR set
- Applies globally to prevent similar issues in other processes