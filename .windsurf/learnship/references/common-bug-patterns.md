<common_bug_patterns>

Patterns for detecting common bugs in AI-generated code. Used by the verifier agent and verify-work workflow to catch issues that pass basic existence checks but fail in practice.

---

## Stub Detection

These patterns indicate placeholder code regardless of file type:

### Comment-based stubs
```bash
grep -E "(TODO|FIXME|XXX|HACK|PLACEHOLDER)" "$file"
grep -E "implement|add later|coming soon|will be" "$file" -i
grep -E "// \.\.\.|/\* \.\.\. \*/|# \.\.\." "$file"
```

### Placeholder text in output
```bash
grep -E "placeholder|lorem ipsum|coming soon|under construction" "$file" -i
grep -E "sample|example|test data|dummy" "$file" -i
```

### Empty or trivial implementations
```bash
grep -E "return null|return undefined|return \{\}|return \[\]" "$file"
grep -E "pass$|\.\.\.|\bnothing\b" "$file"
grep -E "console\.(log|warn|error).*only" "$file"
```

### Hardcoded values where dynamic expected
```bash
grep -E "id.*=.*['\"].*['\"]" "$file"
grep -E "count.*=.*\d+|length.*=.*\d+" "$file"
```

---

## Wiring Gaps

Code exists but isn't connected to the rest of the system:

### Unregistered routes
- Route handler file exists but not imported in the router/app entry
- API endpoint defined but not added to the route table

### Unused exports
- Component exported but never imported anywhere
- Utility function exported but no consumers

### Missing environment variables
- Code references `process.env.X` but `.env.example` doesn't list it
- Config reads a key that's not in the defaults

### Broken imports
- Import path doesn't match actual file location (case sensitivity on Linux)
- Circular dependency that works in dev but fails in production build

---

## State Drift

State management issues that cause subtle bugs:

### Stale state references
- React component reads state that was updated in a different render cycle
- Cache not invalidated after mutation

### Race conditions
- Multiple async operations writing to the same resource
- Optimistic UI update without rollback on failure

### Schema mismatch
- Database migration changes column type but API response type not updated
- Frontend expects field that backend stopped sending

---

## Verification Levels

For each artifact, verify at the appropriate level:

| Level | Check | Method |
|-------|-------|--------|
| 1. Exists | File is present at expected path | `ls [file]` |
| 2. Substantive | Content is real implementation, not placeholder | Stub detection patterns above |
| 3. Wired | Connected to the rest of the system | Import/route check |
| 4. Functional | Actually works when invoked | Run command or manual test |

Levels 1-3 can be checked programmatically. Level 4 often requires human verification (verify-work UAT).

</common_bug_patterns>
