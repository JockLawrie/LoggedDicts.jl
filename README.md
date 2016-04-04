# LoggedDicts

## Why
LoggedDicts is motivated by a need for a lightweight easy-to-use key-value data store similar to Redis, that can also store arbitrary Julia objects.

## Functionality
- A `LoggedDict` is simply a `Dict` for which every write is logged to a user-defined output.
- `LoggedDict`s can be reconstructed from the log.
- `LoggedDict`s can also be directly written to and read from disk.

## Notes
- Since every write is logged, `LoggedDict`s are not suitable in applications with high write frequency.
- Unlike Redis, LoggedDict is not directly optimized for performance. Instead, it leverages existing performance optimizations in Julia itself. If you require better performance than LoggedDict provides, please try an alternative such as Redis or LevelDB...or feel free to implement a performance enhancement!

## Usage
There are two basic functions:
- `get(ld::LoggedDict, keys...)`
- `set!(ld::LoggedDict, keys, value)`

Both functions specify a LoggedDict and an ordered sequence of keys that define a path to a value. `get` simply returns the value found at the path, and `set!` sets (__overwrites__) the value at the path. Other functions that modify the value are listed below. Note that these functions are only defined if they are defined in Julia Base.
- push!(ld, keys, value)
- pop!(ld, keys, value)

```julia
using LoggedDict

# Create and populate a LoggedDict
ld = LoggedDict("my_ld", "mydict.log")       # Init empty LoggedDict, with logs entries recorded in "mydict.log"
set!(ld, "key1", "some_value")
set!(ld, "key2", 2)                          # ld["key2"] equals 2
set!(ld, "key2", "key21", rand(2))           # ld["key2"] equals Dict("key21" => [rand(), rand()]), overwrites previous value of 2
set!(ld, "key3", "key31", Set([1, 2, 3]))    # ld["key3"] equals Dict("key31" => Set([1, 2, 3]))
set!(ld, "key3", "key32", 32)                # ld["key3"] equals Dict("key31" => Set([1, 2, 3]), "key32" => 32)
pop!(ld, "key3", "key31", 2)                 # ld["key3"] equals Dict("key31" => Set([1, 3]), "key32" => 32)
push!(ld, "key3", "key31", 4)                # ld["key3"] equals Dict("key31" => Set([1, 3, 4]), "key32" => 32)
set!(ld, "key4", Dict("key41" => 41, "key42" => 42))    # ld["key4"] equals Dict("key41" => 4, "key42" => 42)

# Write the LoggedDict to disk
write_logged_dict("mydict", ld)
println(ld)

# Read the LoggedDict from disk
ld = read_logged_dict("mydict")
println(ld)
```

## Todo (ideas, rather than plans)
- More functions for modifying existing values. E.g., splice, unshift, enqueue, dequeue, etc.
- Deploying LoggedDict as a stand-alone web service.
- Function for reconstructing the `LoggedDict` from the log.
- Function for compressing the log such that the `LoggedDict` that is recontructed from the compressed log is the same as that reconstructed from the original log.
- For key-value pairs consistent with Redis key-value pairs, wrap the existing syntax with Redis-like syntax so that the same syntax works for both `LoggedDict`s and `RedisConnection`s. Then users can swap out the backend by changing only 1 line...that which defines the data store. For example, `set(d, "key1", "value1")` will work whether d is a `LoggedDict` or a `RedisConnection`.
- Performance optimizations.
