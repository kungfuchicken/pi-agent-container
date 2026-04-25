# Structural Search Pattern Reference

rust-analyzer's structural search uses pattern variables to match AST nodes.

## Pattern Variable Syntax

| Syntax | Matches |
|--------|---------|
| `$name` | Any single AST node |
| `$name:expr` | Expression |
| `$name:stmt` | Statement |
| `$name:ty` | Type |
| `$name:pat` | Pattern |
| `$name:item` | Item (fn, struct, enum, etc.) |
| `$name:path` | Path |
| `$$name` | Zero or more nodes (variadic) |

## Common Search Patterns

### Error Handling

```
# Find all .unwrap() calls
$a.unwrap()

# Find all .expect() calls
$a.expect($msg)

# Find panic! macros
panic!($args)

# Find unwrap_or with default
$a.unwrap_or($default)

# Find ? operator usage
$expr?
```

### Option/Result Patterns

```
# Find if-let Some patterns
if let Some($x) = $y { $$ }

# Find if-let Ok patterns
if let Ok($x) = $y { $$ }

# Find match on Option
match $opt { Some($x) => $$, None => $$ }

# Find map followed by unwrap_or
$a.map($f).unwrap_or($d)

# Find ok_or conversions
$opt.ok_or($err)
```

### Function Signatures

```
# Find functions returning Result
fn $name($args) -> Result<$ok, $err>

# Find async functions
async fn $name($args) -> $ret

# Find public functions
pub fn $name($args) -> $ret

# Find methods with &self
fn $name(&self, $args) -> $ret

# Find methods with &mut self
fn $name(&mut self, $args) -> $ret
```

### Struct/Enum Patterns

```
# Find struct definitions
struct $name { $$ }

# Find tuple structs
struct $name($fields);

# Find enums with specific variant
enum $name { $variant($inner), $$ }

# Find derive macros
#[derive($traits)]
```

### Iterator Patterns

```
# Find for loops
for $item in $iter { $$ }

# Find iterator chains
$iter.iter().map($f)

# Find collect calls
$iter.collect::<$ty>()

# Find filter_map
$iter.filter_map($f)

# Find find calls
$iter.find($pred)
```

### Unsafe Patterns

```
# Find unsafe blocks
unsafe { $$ }

# Find unsafe functions
unsafe fn $name($args) -> $ret

# Find raw pointer dereferences
*$ptr
```

### Clone/Copy Patterns

```
# Find explicit clone calls
$a.clone()

# Find to_owned calls
$a.to_owned()

# Find into conversions
$a.into()

# Find as_ref calls
$a.as_ref()
```

## Structural Search-Replace Examples

### Modernizing Code

```
# Replace unwrap with ?
$a.unwrap() ==>> $a?

# Replace expect with ?
$a.expect($msg) ==>> $a?

# Use map_or instead of map+unwrap_or
$a.map($f).unwrap_or($d) ==>> $a.map_or($d, $f)

# Simplify Option::Some to Some
Option::Some($x) ==>> Some($x)

# Simplify Result::Ok to Ok
Result::Ok($x) ==>> Ok($x)
```

### Refactoring Patterns

```
# Convert to method syntax
Type::method($self, $args) ==>> $self.method($args)

# Inline simple match
match $x { true => $t, false => $f } ==>> if $x { $t } else { $f }

# Use or_else for lazy default
$a.unwrap_or($expr.method()) ==>> $a.unwrap_or_else(|| $expr.method())
```

### API Migrations

```
# Migrate deprecated API
old_function($arg) ==>> new_function($arg)

# Change error type
$e.map_err(OldError) ==>> $e.map_err(NewError)
```

## Tips

1. **Quotes matter**: Wrap patterns in single quotes to prevent shell interpretation
2. **Specificity**: More specific patterns reduce false positives
3. **Variadic `$$`**: Use for "rest of block" or "remaining args"
4. **Type constraints**: Use `:expr`, `:ty` etc. when you need precise matching
5. **Preview first**: Always use `search` before `ssr` to verify matches
