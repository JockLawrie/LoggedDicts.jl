module LoggedDicts

using Logging

import Base: get, push!, pop!

export LoggedDict, get,
       set!, pop!, push!,
       write_logged_dict, read_logged_dict


type LoggedDict
    dct::Dict
    logger::Logging.Logger
    write_counter::Int64    # Counts the writes

    function LoggedDict(dct::Dict, logfile::AbstractString)
        lgr = Logging.configure(output = open(logfile, "a"))
        new(dct, lgr, 0)
    end
    LoggedDict(logfile::AbstractString) = LoggedDict(Dict(), logfile)
    LoggedDict() = LoggedDict(Dict(), "LoggedDict.log")
end


"Write LoggedDict to disk."
function write_logged_dict(filename::AbstractString, ld::LoggedDict)
    f = open(filename, "r+")
    serialize(f, ld)
    close(f)
end


"Read LoggedDict from disk."
function read_logged_dict(filename::AbstractString)
    f  = open(filename, "r")
    ld = deserialize(f)
    close(f)
    ld
end


"Returns the value of ld::LoggedDict located at the path defined by keys..."
function get(ld::LoggedDict, keys...)
    dct = get_containing_dict(ld::LoggedDict, keys...)
    dct[keys[length(keys)]]
end


"""
Sets the value of ld::LoggedDict located at the path defined by keys... equal to value.

Notes:
1. This function assumes that the final argument is the value.
2. If the specified path doesn't exist, it is created.
"""
function set!(ld::LoggedDict, keys_value...)
    nkeys = length(keys_value) - 1    # Final argument is the value (not a key)
    assert(nkeys > 0)
    dct = ld.dct
    for i in 1:(nkeys - 1)
        k = keys_value[i]
	if haskey(dct, k)
            if !(typeof(dct[k]) <: Dict)
                dct[k] = Dict()
	    end
	else
            dct[k] = Dict()
        end
        dct = dct[k]
    end
    k      = keys_value[nkeys]
    dct[k] = keys_value[nkeys + 1]
    ld.write_counter += 1
    info(ld.logger, "$(ld.write_counter): SET $keys_value")
end


"""
Pushes value onto the value of ld::LoggedDict located at the path defined by keys...

Notes:
1. This function assumes that the final argument is the value.
2. The specified path must exist, otherwise an error is raised.
"""
function push!(ld::LoggedDict, keys_value...)
    val_idx = length(keys_value)    # value is the last element of keys_value
    nkeys   = val_idx - 1           # Final argument is the value (not a key)
    keys    = keys_value[1:nkeys]
    dct     = get_containing_dict(ld::LoggedDict, keys...)
    push!(dct[keys_value[nkeys]], keys_value[val_idx])
    ld.write_counter += 1
    info(ld.logger, "$(ld.write_counter): PUSH $keys_value")
end


"""
Pops value from the value of ld::LoggedDict located at the path defined by keys...

Notes:
1. This function assumes that the final argument is the value.
2. The specified path must exist, otherwise an error is raised.
"""
function pop!(ld::LoggedDict, keys_value...)
    val_idx = length(keys_value)    # value is the last element of keys_value
    nkeys   = val_idx - 1           # Final argument is the value (not a key)
    keys    = keys_value[1:nkeys]
    dct     = get_containing_dict(ld::LoggedDict, keys...)
    pop!(dct[keys_value[nkeys]], keys_value[val_idx])
    ld.write_counter += 1
    info(ld.logger, "$(ld.write_counter): POP $keys_value")
end


"""
Returns: Dict that contains the path defined by keys.
Raises an error if the path doesn't exist.
"""
function get_containing_dict(ld::LoggedDict, keys...)
    nkeys = length(keys)
    assert(nkeys > 0)
    dct = ld.dct
    for i in 1:(nkeys - 1)
        k = keys[i]
        if !haskey(dct, k)
            error("LoggedDict has no path $(keys[1:i]).")
        end
        dct = dct[k]
    end
    dct
end


end # module
