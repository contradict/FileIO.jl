const ActionSource = Union{PkgId,Module}
const sym2loader = Dict{Symbol,Vector{ActionSource}}()
const sym2saver  = Dict{Symbol,Vector{ActionSource}}()

for (applicable_, add_, dict_) in (
        (:applicable_loaders, :add_loader, :sym2loader),
        (:applicable_savers,  :add_saver,  :sym2saver))
    @eval begin
        function $applicable_(sym::Symbol)
            ret = get($dict_, sym, nothing)
            ret === nothing && error(string("No ", $applicable_, " found for ", sym))
            return ret
        end
        $add_(@nospecialize(fmt::Type), id::Union{ActionSource,Pair}) = $add_(formatname(fmt)::Symbol, id)
        function $add_(sym::Symbol, id::ActionSource)
            list = get!(Vector{ActionSource}, $dict_, sym)
            push!(list, id)
        end
        $add_(sym::Symbol, pkg::Pair{<:Union{String,Symbol}, UUID}) = $add_(sym, Base.PkgId(pkg.second, String(pkg.first)))
        function $add_(fmt, pkg)
            # TODO: delete this method in FileIO v2
            sym = isa(fmt, Symbol) ? fmt : formatname(fmt)::Symbol
            Base.depwarn(string($add_) * "(fmt, pkg::$(typeof(pkg))) is deprecated, supply `pkg` as a Module or `name=>uuid`", Symbol($add_))
            pkg === :MimeWriter && return $add_(sym, MimeWriter)
            # Try to look it up in the caller's environment
            pkgname = string(pkg)
            id = Base.identify_package(pkgname)
            if id === nothing
                # See if it's in Main
                pkgsym = Symbol(pkg)
                if isdefined(Main, pkgsym)
                    id = getfield(Main, pkgsym)
                    if !isa(id, Module)
                        id = nothing
                    end
                end
                if id === nothing
                    # Look it up in the registries. The tricky part here is supporting different Julia versions
                    ctx = Pkg.API.Context()
                    uuids = UUID[]
                    @static if Base.VERSION >= v"1.2"
                        if hasfield(typeof(ctx), :registries)
                            for reg in ctx.registries
                                append!(uuids, Pkg.Registry.uuids_from_name(reg, pkgname))
                            end
                        else
                            ctx = Pkg.API.Context!(ctx)
                            if isdefined(Pkg.Types, :find_registered!) && hasmethod(Pkg.Types.find_registered!, (typeof(ctx.env), Vector{String}))
                                Pkg.Types.find_registered!(ctx.env, [pkgname])
                            elseif isdefined(Pkg.Types, :find_registered!) && hasmethod(Pkg.Types.find_registered!, (typeof(ctx), Vector{String}))
                                Pkg.Types.find_registered!(ctx, [pkgname])
                            end
                            append!(uuids, get(ctx.env.uuids, pkgname, UUID[]))
                        end
                    else
                        Pkg.Types.find_registered!(ctx.env)
                        append!(uuids, get(ctx.env.uuids, pkgname, UUID[]))
                    end
                    isempty(uuids) && throw(ArgumentError("no UUID found for $pkg"))
                    length(uuids) == 1 || throw(ArgumentError("multiple UUIDs found for $pkg"))
                    id = PkgId(uuids[1], pkgname)
                end
            end
            $add_(sym, id)
        end
    end
end


"""
    add_loader(fmt, :Package=>uuid)
    add_loader(fmt, [:Package=>uuid, specifiers...])

Declare that format `fmt` can be loaded with package `:Package`.
Specifiers include `OSX`, `Unix`, `Windows` and `Linux` to restrict usage to particular operating systems.
"""
add_loader

"""
    add_saver(fmt, :Package=>uuid)
    add_saver(fmt, [:Package=>uuid, specifiers...])

Declare that format `fmt` can be saved with package `:Package`.
Specifiers include `OSX`, `Unix`, `Windows` and `Linux` to restrict usage to particular operating systems.
"""
add_saver

"""
- `load(filename)` loads the contents of a formatted file, trying to infer
the format from `filename` and/or magic bytes in the file.
- `load(strm)` loads from an `IOStream` or similar object. In this case,
there is no filename extension, so we rely on the magic bytes for format
identification.
- `load(File{format"PNG"}(filename))` specifies the format directly, and bypasses inference.
- `load(Stream{format"PNG"}(io))` specifies the format directly, and bypasses inference.
- `load(f; options...)` passes keyword arguments on to the loader.
"""
load

"""
Some packages may implement a streaming API, where the contents of the file can
be read in chunks and processed, rather than all at once. Reading from these
higher-level streams should return a formatted object, like an image or chunk of
video or audio.

- `loadstreaming(filename)` loads the contents of a formatted file, trying to infer
the format from `filename` and/or magic bytes in the file. It returns a streaming
type that can be read from in chunks, rather than loading the whole contents all
at once
- `loadstreaming(strm)` loads the stream from an `IOStream` or similar object.
In this case, there is no filename extension, so we rely on the magic bytes
for format identification.
- `loadstreaming(File{format"WAV"}(filename))` specifies the format directly, and
bypasses inference.
- `loadstreaming(Stream{format"WAV"}(io))` specifies the format directly, and
bypasses inference.
- `loadstreaming(f; options...)` passes keyword arguments on to the loader.
"""
loadstreaming

"""
- `save(filename, data...)` saves the contents of a formatted file,
trying to infer the format from `filename`.
- `save(Stream{format"PNG"}(io), data...)` specifies the format directly, and bypasses inference.
- `save(File{format"PNG"}(filename), data...)` specifies the format directly, and bypasses inference.
- `save(f, data...; options...)` passes keyword arguments on to the saver.
"""
save

"""
Some packages may implement a streaming API, where the contents of the file can
be written in chunks, rather than all at once. These higher-level streams should
accept formatted objects, like an image or chunk of video or audio.

- `savestreaming(filename, data...)` saves the contents of a formatted file,
trying to infer the format from `filename`.
- `savestreaming(File{format"WAV"}(filename))` specifies the format directly, and
bypasses inference.
- `savestreaming(Stream{format"WAV"}(io))` specifies the format directly, and
bypasses inference.
- `savestreaming(f, data...; options...)` passes keyword arguments on to the saver.
"""
savestreaming

# if a bare filename or IO stream are given, query for the format and dispatch
# to the formatted handlers below
for fn in (:load, :loadstreaming, :metadata)
    fnq = QuoteNode(fn)
    @eval function $fn(file, args...; options...)
        checkpath_load(file)
        sym = querysym(file)
        libraries = applicable_loaders(sym)
        return action($fnq, libraries, sym, file, args...; options...)
    end
    # Version that bypasses format-inference
    @eval function $fn(@nospecialize(file::Formatted), args...; options...)
        checkpath_load(filename(file))
        sym = formatname(file)::Symbol
        libraries = applicable_loaders(sym)
        return action($fnq, libraries, file, args...; options...)
    end
end
for fn in (:save, :savestreaming)
    fnq = QuoteNode(fn)
    @eval function $fn(file, args...; options...)
        checkpath_save(file)
        sym = querysym(file; checkfile=false)
        libraries = applicable_savers(sym)
        return action($fnq, libraries, sym, file, args...; options...)
    end
    @eval function $fn(@nospecialize(file::Formatted), args...; options...)
        checkpath_save(filename(file))
        sym = formatname(file)::Symbol
        libraries = applicable_savers(sym)
        return action($fnq, libraries, file, args...; options...)
    end
    @eval function $fn(@nospecialize(fmt::Type), file, args...; options...)
        checkpath_save(file)
        sym = formatname(fmt)::Symbol
        libraries = applicable_savers(sym)
        return action($fnq, libraries, sym, file, args...; options...)
    end
end

# return a save function, so you can do `thing_to_save |> save("filename.ext")`
function save(file; options...)
    sym = querysym(file; checkfile=false)
    libraries = applicable_loaders(sym)
    return data -> action(:save, libraries, sym, file, data; options...)
end

# do-syntax for streaming IO
for fn in (:loadstreaming, :savestreaming)
    @eval function $fn(@nospecialize(f::Function), @nospecialize(args...); @nospecialize(kwargs...))
        str = $fn(args...; kwargs...)
        try
            f(str)
        finally
            close(str)
        end
    end
end

function checkpath_load(file)
    file === nothing && return nothing   # likely stream io
    !isfile(file) && throw(ArgumentError("No file exists at given path: $file"))
    return nothing
end
function checkpath_save(file)
    file === nothing && return nothing
    isa(file, IO) && return nothing
    isdir(file) && throw(ArgumentError("Given file path is a directory: $file"))
    dn = dirname(file)
    !isdir(dn) && mkpath(dn)
    return nothing
end

action(call::Symbol, libraries::Vector{ActionSource}, sym::Symbol, io::IO, args...; options...) =
    action(call, libraries, Stream(DataFormat{sym}, io), args...; options...)
action(call::Symbol, libraries::Vector{ActionSource}, sym::Symbol, file, args...; options...) =
    action(call, libraries, File{DataFormat{sym}}(file), args...; options...)

# To test for broken packages which extend FileIO functions
const fileiofuncs = Dict{Symbol,Function}(:load => load,
                                          :loadstring => loadstreaming,
                                          :metadata => metadata,
                                          :save => save,
                                          :savestreaming => savestreaming)

function action(call::Symbol, libraries::Vector{ActionSource}, @nospecialize(file::Formatted), args...; options...)
    issave = call ∈ (:save, :savestreaming)
    failures = Tuple{Any,ActionSource}[]
    pkgfuncname = Symbol("fileio_", call)
    local mod
    for library in libraries
        try
            mod = isa(library, Module) ? library : Base.require(library)
            f = if isdefined(mod, pkgfuncname)
                getfield(mod, pkgfuncname)
            else
                getfield(mod, call)
            end
            if f === get(fileiofuncs, call, nothing)
                argtyps = map(Core.Typeof, args)
                m = which(f, (typeof(file), argtyps...))
                if m == which(f, (Formatted, argtyps...))
                    throw(SpecError(mod, call))
                end
                @warn "$mod incorrectly extends FileIO functions (see FileIO documentation)"
            end
            return Base.invokelatest(f, file, args...; options...)
        catch e
            if isa(e, MethodError) || isa(e, SpecError)
                str = "neither $call nor $pkgfuncname is defined"
                e = issave ? WriterError(string(mod), str) : LoaderError(string(mod), str)
            end
            push!(failures, (e, library))
        end
    end
    handle_exceptions(failures, "$call $(repr(file))")
end
