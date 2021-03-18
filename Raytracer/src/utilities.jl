"""`is_little_endian()`
Return bool about endianness of host system"""
function is_little_endian()
    return ENDIAN_BOM == 0x04030201
end