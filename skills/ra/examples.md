# rust-analyzer Skill Examples

Real-world examples of using the `/ra` skill effectively.

## Code Quality Audit

**Scenario**: Review a project for common issues before a release.

```
/ra diag
```

Then follow up with:

```
/ra refs
```

This combination finds both compiler issues and unresolved references.

## Finding Unwrap Calls

**Scenario**: Identify all `.unwrap()` calls that might panic in production.

```
/ra search '$a.unwrap()'
```

For a stricter search that also catches `expect`:

```
/ra search '$a.expect($msg)'
```

## Previewing Refactors

**Scenario**: Want to replace all `unwrap()` with `?` operator.

First, preview what would change:

```
/ra search '$a.unwrap()'
```

Then see the transformation:

```
/ra ssr '$a.unwrap() ==>> $a?'
```

Review the output, then apply changes manually to files you want to modify.

## Finding Specific Patterns

**Scenario**: Find all functions that return `Result` types.

```
/ra search 'fn $name($args) -> Result<$ok, $err>'
```

**Scenario**: Find all async functions.

```
/ra search 'async fn $name($args) -> $ret'
```

**Scenario**: Find all unsafe blocks.

```
/ra search 'unsafe { $$ }'
```

## Iterator Chain Analysis

**Scenario**: Find potentially inefficient iterator patterns.

```
# Find map followed by unwrap_or (could use map_or)
/ra search '$a.map($f).unwrap_or($d)'

# Find collect followed by len (could use count)
/ra search '$iter.collect::<Vec<_>>().len()'
```

## Error Handling Review

**Scenario**: Audit error handling patterns.

```
# Find all panic! macros
/ra search 'panic!($args)'

# Find all todo! macros
/ra search 'todo!($args)'

# Find all unimplemented! macros
/ra search 'unimplemented!($args)'
```

## Project Statistics

**Scenario**: Get an overview of project complexity.

```
/ra stats
```

Useful for:
- Understanding project size before diving in
- Comparing before/after refactoring
- Finding crates that need attention

## Multi-Crate Workspace

**Scenario**: Analyze a specific crate in a workspace.

```
/ra diag path/to/specific/crate
```

Or analyze the whole workspace:

```
/ra diag .
```

## Combining with Other Analysis

After `/ra diag` finds issues, use Claude's normal capabilities:

1. Read the problematic files
2. Understand the context
3. Propose fixes
4. Apply changes via Edit tool

The skill provides discovery; Claude provides the fix.
