### "Package registry"
# Useful for packages that get used more than once below
# Please alphabetize
const idCSVFiles = :CSVFiles => UUID("5d742f6a-9f54-50ce-8119-2520741973ca")
const idImageIO = :ImageIO => UUID("82e4d734-157c-48bb-816b-45c225c6df19")
const idImageMagick = :ImageMagick => UUID("6218d12a-5da1-5696-b52f-db25d2ecc6d1")
const idMeshIO = :MeshIO => UUID("7269a6da-0436-5bbc-96c2-40638cbb6118")
const idNetpbm = :Netpbm => UUID("f09324ee-3d7c-5217-9330-fc30815ba969")
const idQuartzImageIO = :QuartzImageIO => UUID("dca85d43-d64c-5e67-8c65-017450d5d020")
const idRData = :RData => UUID("df47a6cb-8c03-5eed-afd8-b6050d6c41da")
const idStatFiles = :StatFiles => UUID("1463e38c-9381-5320-bcd4-4134955f093a")
const idVegaLite = :VegaLite => UUID("112f6efa-9a02-5b7d-90c0-432ed331239a")

### Simple cases

# data formats
add_format(format"JLD", (unsafe_wrap(Vector{UInt8}, "Julia data file (HDF5), version 0.0"),
                         unsafe_wrap(Vector{UInt8}, "Julia data file (HDF5), version 0.1")), ".jld", [:JLD => UUID("4138dd39-2aa7-5051-a626-17a0bb65d9c8")])
add_format(format"JLD2", (unsafe_wrap(Vector{UInt8},"Julia data file (HDF5), version 0.2"),
                          unsafe_wrap(Vector{UInt8}, "HDF5-based Julia Data Format, version ")), ".jld2", [:JLD2 => UUID("033835bb-8acc-5ee8-8aae-3f567f8a3819")])
add_format(format"GZIP", [0x1f, 0x8b], ".gz", [:Libz => UUID("2ec943e9-cfe8-584d-b93d-64dcb6d567b7")])
add_format(format"BSON",(),".bson", [:BSON => UUID("fbb218c0-5317-5bc6-957e-2ee96dd4b1f0")])
add_format(format"JLSO", (), ".jlso", [:JLSO => UUID("9da8a3cd-07a3-59c0-a743-3fdc52c30d11")])

# test for RD?n magic sequence at the beginning of R data input stream
function detect_rdata(io)
    seekstart(io)
    read(io, UInt8) == UInt8('R') &&
    read(io, UInt8) == UInt8('D') &&
    read(io, UInt8) in (UInt8('A'), UInt8('B'), UInt8('X')) &&
    read(io, UInt8) in (UInt8('2'), UInt8('3')) &&
    (c = read(io, UInt8); c == UInt8('\n') || (c == UInt8('\r') && read(io, UInt8) == UInt8('\n')))
end

add_format(format"RData", detect_rdata, [".rda", ".RData", ".rdata"], [idRData, LOAD])

function detect_rdata_single(io)
    seekstart(io)
    res = read(io, UInt8) in (UInt8('A'), UInt8('B'), UInt8('X')) &&
        (c = read(io, UInt8); c == UInt8('\n') || (c == UInt8('\r') && read(io, UInt8) == UInt8('\n')))
    seekstart(io)
    return res
end

add_format(format"RDataSingle", detect_rdata_single, [".rds"], [idRData, LOAD])

add_format(format"CSV", (), [".csv"], [idCSVFiles])
add_format(format"TSV", (), [".tsv"], [idCSVFiles])
add_format(format"Feather", "FEA1", [".feather"], [:FeatherFiles => UUID("b675d258-116a-5741-b937-b79f054b0542")])
add_format(format"Excel", (), [".xls", ".xlsx"], [:ExcelFiles => UUID("89b67f3b-d1aa-5f6f-9ca4-282e8d98620d")])
add_format(format"Stata", (), [".dta"], [idStatFiles, LOAD])
add_format(format"SPSS", "\$FL2", [".sav"], [idStatFiles, LOAD])
add_format(format"SAS", UInt8[0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0xc2, 0xea, 0x81, 0x60,0xb3, 0x14, 0x11,
    0xcf, 0xbd, 0x92, 0x08, 0x00, 0x09, 0xc7, 0x31, 0x8c, 0x18, 0x1f,
    0x10, 0x11], [".sas7bdat"], [idStatFiles, LOAD])
add_format(format"Parquet", "PAR1", [".parquet"], [:ParquetFiles => UUID("46a55296-af5a-53b0-aaa0-97023b66127f"), LOAD])

# Image formats
add_format(format"PBMBinary", b"P4", ".pbm", [idImageIO], [idNetpbm], [idImageMagick])
add_format(format"PGMBinary", b"P5", ".pgm", [idImageIO], [idNetpbm])
add_format(format"PPMBinary", b"P6", ".ppm", [idImageIO], [idNetpbm])
add_format(format"PBMText",   b"P1", ".pbm", [idImageIO], [idNetpbm], [idImageMagick, LOAD])
add_format(format"PGMText",   b"P2", ".pgm", [idImageIO], [idNetpbm], [idImageMagick, LOAD])
add_format(format"PPMText",   b"P3", ".ppm", [idImageIO], [idNetpbm], [idImageMagick, LOAD])

add_format(format"NRRD", "NRRD", [".nrrd", ".nhdr"], [:NRRD => UUID("9bb6cfbd-7763-5393-b1b5-1c8e09872146")])

add_format(format"AndorSIF", "Andor Technology Multi-Channel File", ".sif", [:AndorSIF => UUID("d04cd5f8-5917-4006-ac6f-d139328806a7"), LOAD])

add_format(format"FLO", b"PIEH", ".flo", [:OpticalFlowUtils => UUID("ab0dad50-ab19-448c-b796-13553ec8b2d3")])

add_format(format"CRW", UInt8[0x49,0x49,0x1a,0x00,0x00,0x00,0x48,0x45], ".crw", [idImageMagick])
add_format(format"CUR", UInt8[0x00,0x00,0x02,0x00],                     ".cur", [idImageMagick])
add_format(format"DCX", UInt8[0xb1,0x68,0xde,0x3a],                     ".dcx", [idImageMagick])
add_format(format"DOT", UInt8[0xd0,0xcf,0x11,0xe0,0xa1,0xb1,0x1a,0xe1], ".dot", [idImageMagick])
add_format(format"EPS", UInt8[0x25,0x21,0x50,0x53,0x2d,0x41,0x64,0x6f], ".eps", [idImageMagick], [MimeWriter, SAVE])
add_format(format"HDR", UInt8[0x23,0x3f,0x52,0x41,0x44,0x49,0x41,0x4e], ".hdr", [idImageMagick])
add_format(format"ICO", UInt8[0x00,0x00,0x01,0x00],                     ".ico", [idImageMagick])
add_format(format"INFO", UInt8[0x7a,0x62,0x65,0x78],                    ".info",[idImageMagick])
add_format(format"JP2", UInt8[0x00,0x00,0x00,0x0c,0x6a,0x50,0x20,0x20], ".jp2", [idImageMagick])
add_format(format"PDB", UInt8[0x73,0x7a,0x65,0x7a],                     ".pdb", [idImageMagick])
add_format(format"PDF", UInt8[0x25,0x50,0x44,0x46],                     ".pdf", [idImageMagick], [MimeWriter, SAVE])
add_format(format"PGM", UInt8[0x50,0x35,0x0a],                          ".pgm", [idImageMagick])
add_format(format"PSD", UInt8[0x38,0x42,0x50,0x53],                     ".psd", [idImageMagick])
add_format(format"RGB", UInt8[0x01,0xda,0x01,0x01,0x00,0x03],           ".rgb", [idImageMagick])
add_format(format"WMF", UInt8[0xd7,0xcd,0xc6,0x9a],                     ".wmf", [idImageMagick])
add_format(format"WPG", UInt8[0xff,0x57,0x50,0x43],                     ".wpg", [idImageMagick])
add_format(format"Imagine", "IMAGINE",                                  ".imagine", [:ImagineFormat => UUID("4bab44a2-5ff2-5a6b-8e10-825fb9ac126a")])

add_format(
    format"TGA",
    (),
    ".tga",
    [idQuartzImageIO, OSX],
    [idImageMagick]
)
add_format(
    format"GIF",
    UInt8[0x47,0x49,0x46,0x38],
    ".gif",
    [idQuartzImageIO, OSX],
    [idImageMagick]
)
add_format(
    format"PNG",
    UInt8[0x89,0x50,0x4e,0x47,0x0d,0x0a,0x1a,0x0a],
    ".png",
    [idImageIO],
    [idQuartzImageIO, OSX],
    [idImageMagick],
    [MimeWriter, SAVE]
)
add_format(
    format"JPEG",
    UInt8[0xff,0xd8,0xff],
    [".jpeg", ".jpg", ".JPG"],
    [idQuartzImageIO, OSX],
    [idImageMagick]
) # 0xe1
add_format(
    format"BMP",
    UInt8[0x42,0x4d],
    ".bmp",
    [idQuartzImageIO, OSX],
    [idImageMagick]
)
add_format(
    format"PCX",
    (UInt8[0x0a,0x02], UInt8[0x0a,0x05]),
    ".pcx",
    [idImageMagick]
)
add_format(
    format"SVG",
    (),
    ".svg",
    [MimeWriter, SAVE]
)

#=
add_format(format"NPY", UInt8[0x93, 'N', 'U', 'M', 'P', 'Y'], ".npy")
add_loader(format"NPZ", :NPZ)
add_saver(format"NPZ", :NPZ)

add_format(format"ZIP", [0x50,0x4b,0x03,0x04], ".zip")
add_loader(format"ZIP", :ZipeFile)
add_saver(format"ZIP", :ZipeFile)
=#

#Shader files
# add_format(format"GLSLShader", (), [".frag", ".vert", ".geom", ".comp"], [:GLAbstraction])

# Mesh formats
add_format(format"OBJ", (), ".obj", [idMeshIO])
add_format(format"PLY_ASCII", "ply\nformat ascii 1.0", ".ply", [idMeshIO])
add_format(format"PLY_BINARY", "ply\nformat binary_little_endian 1.0", ".ply", [idMeshIO])
add_format(format"2DM", "MESH2D", ".2dm", [idMeshIO])
add_format(format"OFF", "OFF", ".off", [idMeshIO])
add_format(format"MSH", (), ".msh", [idMeshIO])

# GSLIB/SGeMS format (http://gslib.com)
add_format(format"GSLIB", (), [".gslib",".sgems"], [:GslibIO => UUID("4610876b-9b01-57c8-9ad9-06315f1a66a5")])

### Audio formats
function detectwav(io)
    getlength(io) >= 12 || return false
    buf = Vector{UInt8}(undef, 4)
    read!(io, buf)
    buf == b"RIFF" || return false
    seek(io, 8)
    read!(io, buf)
    submagic == b"WAVE"
end
add_format(format"WAV", detectwav, ".wav", [:WAV => UUID("8149f6b0-98f6-5db9-b78f-408fbbb8ef88")])
add_format(format"FLAC","fLaC",".flac",[:FLAC => UUID("abae9e3b-a9a0-4778-b5c6-ca109b507d99")])

## Profile data
add_format(format"JLPROF", [0x4a, 0x4c, 0x50, 0x52, 0x4f, 0x46, 0x01, 0x00], ".jlprof", [:FlameGraphs => UUID("08572546-2f56-4bcf-ba4e-bab62c3a3f89")])  # magic is "JLPROF" followed by [0x01, 0x00]

### Complex cases

#=
The bedGraph file format is line-based, and its magic bytes may occur at an indeterminate location within its header.
Certain conditions must be imposed to constrain the scan for its magic bytes and prevent unnecessary scanning of whole files.
Lines must start with particular byte strings that are recognisable to the bedGraph format to allow the scan for its magic bytes to continue.
=#
function detect_bedgraph(io)

    bedgraph_magic = b"type=bedGraph"

    # Line start constraints.
    browser_magic = b"browser"
    track_magic   = b"track"
    comment_magic = b"#"

    keep_scanning = false # Allow scan to continue until new line.
    ontrack = false # On the track that may contain the magic bytes.

    # Check lines for magic bytes.
    pos = 1
    while !eof(io)
        r = read(io, UInt8)

        # Check whether the line starts with a comment.
        if !keep_scanning && pos == 1 && comment_magic[pos] == r
            keep_scanning = true # Now scanning for newline.
            pos += 1
            continue
        end

        # Check whether the line starts with "browser".
        if !keep_scanning && browser_magic[pos] == r
            if pos >= length(browser_magic)
                keep_scanning = true # Now scanning for newline.
            end
            pos += 1
            continue
        end

        # Check whether the line starts with "track".
        if !keep_scanning && track_magic[pos] == r
            if pos >= length(track_magic)
                ontrack = true # Found the "track" line where the magic bytes may exist.
                keep_scanning = true # Allow scan to continue until the end of the current line.
            end
            pos += 1
            continue
        end

        # Check whether the line has ended.
        if UInt8('\n') == r
            keep_scanning = false
            ontrack = false
            pos = 1
            continue
        end

        # On "track" and checking whether "type=bedGraph" is contained within the line.
        if ontrack && bedgraph_magic[pos] == r
            pos >= length(bedgraph_magic) && return true
            pos += 1
            continue
        end

        pos = 1

        # Allow whitespace.
        if UInt8('\t') == r || UInt8(' ') == r
            continue
        end

        # Check whether on "track" and allowed to continue scanning.
        if !keep_scanning && !ontrack
            break # Ending scan for bedGraph magic.
        end

    end

    return false
end
add_format(format"bedGraph", detect_bedgraph, [".bedgraph"], [:BedgraphFiles => UUID("85eb9095-274b-55ce-be28-9e90f41ac741")])

# Handle OME-TIFFs, which are identical to normal TIFFs with the primary difference being the filename and embedded XML metadata
const tiff_magic = (UInt8[0x4d,0x4d,0x00,0x2a], UInt8[0x4d,0x4d,0x00,0x2b], UInt8[0x49,0x49,0x2a,0x00],UInt8[0x49,0x49,0x2b,0x00])
function detecttiff(io)
    getlength(io) >= 4 || return false
    magic = read!(io, Vector{UInt8}(undef, 4))
    # do any of the first 4 bytes match any of the 4 possible combinations of tiff magics
    return any(map(x->all(magic .== x), tiff_magic))
end
# normal TIFF
detect_noometiff(io) = detecttiff(io) && !(endswith(io.name, ".ome.tif>") || endswith(io.name, ".ome.tiff>"))
add_format(format"TIFF", detect_noometiff, [".tiff", ".tif"], [idQuartzImageIO, OSX], [idImageMagick])
# OME-TIFF
detect_ometiff(io) = detecttiff(io) && (endswith(io.name, ".ome.tif>") || endswith(io.name, ".ome.tiff>"))
add_format(format"OMETIFF", detect_ometiff, [".tif", ".tiff"], [:OMETIFF => UUID("2d0ec36b-e807-5756-994b-45af29551fcf")])

# custom skipmagic functions for function-based tiff magic detection
skipmagic(io, ::typeof(detect_ometiff)) = seek(io, 4)
skipmagic(io, ::typeof(detect_noometiff)) = seek(io, 4)

# AVI is a subtype of RIFF, as is WAV
function detectavi(io)
    getlength(io) >= 12 || return false
    magic = read!(io, Vector{UInt8}(undef, 4))
    magic == b"RIFF" || return false
    seek(io, 8)
    submagic = read!(io, Vector{UInt8}(undef, 4))

    submagic == b"AVI "
end
add_format(format"AVI", detectavi, ".avi", [idImageMagick])

# HDF5: the complication is that the magic bytes may start at
# 0, 512, 1024, 2048, or any multiple of 2 thereafter
const h5magic = [0x89,0x48,0x44,0x46,0x0d,0x0a,0x1a,0x0a]
function detecthdf5(io)
    position(io) == 0 || return false
    len = getlength(io)
    magic = Vector{UInt8}(undef, length(h5magic))
    pos = position(io)
    while pos+length(h5magic) <= len
        read!(io, magic)
        if magic == h5magic
            return true
        end
        pos = pos == 0 ? 512 : 2*pos
        if pos < len
            seek(io, pos)
        end
    end
    false
end
add_format(format"HDF5", detecthdf5, [".h5", ".hdf5"], [:HDF5 => UUID("f67ccb44-e63f-5c2f-98bd-6dc0ccc4ba2f")])

function detect_stlascii(io)
    pos = position(io)
    try
        len = getlength(io, pos)
        len < 80 && return false
        header = read(io, 80) # skip header
        seek(io, pos)
        header[1:6] == b"solid " && !detect_stlbinary(io)
    finally
        seek(io, pos)
    end
end

function detect_stlbinary(io)
    size_header = 80 + sizeof(UInt32)
    size_triangleblock = (4 * 3 * sizeof(Float32)) + sizeof(UInt16)
    pos = position(io)
    len = getlength(io, pos)
    len < size_header && return false

    skip(io, 80) # skip header
    number_of_triangle_blocks = read(io, UInt32)
     #1 normal, 3 vertices in Float32 + attrib count, usually 0
    len != (number_of_triangle_blocks*size_triangleblock)+size_header && (seekstart(io); return false)
    skip(io, number_of_triangle_blocks*size_triangleblock-sizeof(UInt16))
    attrib_byte_count = read(io, UInt16) # read last attrib_byte
    attrib_byte_count != zero(UInt16) && (seekstart(io); return false) # should be zero as not used
    result = eof(io) # if end of file, we have a stl!
    return result
end
add_format(format"STL_ASCII", detect_stlascii, [".stl", ".STL"], [idMeshIO])
add_format(format"STL_BINARY", detect_stlbinary, [".stl", ".STL"], [idMeshIO])

add_format(format"FITS",
           # See https://www.loc.gov/preservation/digital/formats/fdd/fdd000317.shtml#sign
           [0x53,0x49,0x4d,0x50,0x4c,0x45,0x20,0x20,0x3d,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x54],
           [".fit", ".fits", ".fts", ".FIT", ".FITS", ".FTS"], [:FITSIO => UUID("525bcba6-941b-5504-bd06-fd0dc1a4d2eb")])

add_format(format"RawArray", [0x61,0x72,0x61,0x77,0x72,0x72,0x79,0x61], ".ra", [:RawArray => UUID("d3d335b2-f152-507c-820e-958e337efb65")])

add_format(format"MetaImage", "ObjectType", ".mhd", [:MetaImageFormat => UUID("1950589f-4d68-56f0-9b94-9d8646217309")])

add_format(format"vegalite", (), [".vegalite"], [idVegaLite])
add_format(format"vega", (), [".vega"], [:Vega => UUID("239c3e63-733f-47ad-beb7-a12fde22c578")], [idVegaLite, SAVE])

add_format(format"FCS", "FCS", [".fcs"], [:FCSFiles => UUID("d76558cf-badf-52d4-a17e-381ab0b0d937")])

add_format(format"HTML", (), [".html", ".htm"], [MimeWriter, SAVE])
