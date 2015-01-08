using FITSIO
using Base.Test

# -----------------------------------------------------------------------------
# Images

# Create a FITS instance and loop over supported types.
fname = tempname() * ".fits"
f = FITS(fname, "w")
for T in [Uint8, Int8, Uint16, Int16, Uint32, Int32, Int64,
          Float32, Float64]
    indata = reshape(T[1:100], 5, 20)

    # Test writing the data to a new extension
    write(f, indata)

    # test reading the full array
    outdata = read(f[end])    
    @test indata == outdata
    @test eltype(indata) == eltype(outdata)

    # test reading subsets of the array
    @test f[end][:, :] == indata
    @test f[end][4, 1:10] == indata[4, 1:10]
    @test f[end][:, 1:2:10] == indata[:, 1:2:10]
end
close(f)
if isfile(fname)
    rm(fname)
end

# copy_section()
fname1 = tempname() * ".fits"
f1 = FITS(fname1, "w")
indata = reshape(Float32[1:400], 20, 20)
write(f1, indata)

fname2 = tempname() * ".fits"
f2 = FITS(fname2, "w")
copy_section(f1[1], f2, 1:10, 1:10)
copy_section(f1[1], f2, 1:10, 1:2:20)
outdata = read(f2[1])
@test outdata == indata[1:10, 1:10]
outdata = read(f2[2])
@test outdata == indata[1:10, 1:2:20]
close(f1)
close(f2)
if isfile(fname1)
    rm(fname1)
end
if isfile(fname2)
    rm(fname2)
end

# -----------------------------------------------------------------------------
# FITSHeader

fname = tempname() * ".fits"
f = FITS(fname, "w")
inhdr = FITSHeader(["FLTKEY", "INTKEY", "BOOLKEY", "STRKEY", "COMMENT",
                    "HISTORY"],
                   [1.0, 1, true, "string value", nothing, nothing],
                   ["floating point keyword",
                    "",
                    "boolean keyword",
                    "string value",
                    "this is a comment",
                    "this is a history"])

inhdr["INTKEY"] = 2  # test setting by key
inhdr[1] = 2.0  # test settting by index
setcomment!(inhdr, "INTKEY", "integer keyword") # test setting a comment

indata = reshape(Float32[1:100], 5, 20)
write(f, indata; header=inhdr)
outhdr = readheader(f[1])
@test outhdr["FLTKEY"] === 2.0
@test outhdr["INTKEY"] === 2
@test outhdr["BOOLKEY"] === true
@test outhdr["STRKEY"] == "string value"
@test getcomment(outhdr, 13) == "this is a comment"
@test getcomment(outhdr, 14) == "this is a history"
@test length(outhdr) == 14
@test haskey(outhdr, "FLTKEY")

# Read single keywords
@test readkey(f[1], 9) == ("FLTKEY", 2.0, "floating point keyword")
@test readkey(f[1], "FLTKEY") == (2.0, "floating point keyword")

close(f)
if isfile(fname)
    rm(fname)
end

println("All tests passed.")
