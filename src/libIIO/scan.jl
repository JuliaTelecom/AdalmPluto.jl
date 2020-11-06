function C_iio_context_info_get_description(context::Ptr{iio_context_info})
    return Base.unsafe_string(ccall(
        (:iio_context_info_get_description, libIIO),
        Cstring, (Ptr{iio_context_info},),
        context
    ));
end

function C_iio_context_info_get_uri(context::Ptr{iio_context_info})
    return Base.unsafe_string(ccall(
        (:iio_context_info_get_uri, libIIO),
        Cstring, (Ptr{iio_context_info},),
        context
    ));
end

function C_iio_context_info_list_free(ptr_context::Ptr{Ptr{iio_context_info}})
    ccall(
        (:iio_context_info_list_free, libIIO),
        Cvoid, (Ptr{Ptr{iio_context_info}},),
        ptr_context
    );
end

function C_iio_create_scan_block(backend::String, flags::UInt32=UInt32(0))
    @assert_scan_block scan_block = ccall(
        (:iio_create_scan_block, libIIO),
        Ptr{iio_scan_block}, (Cstring, Cuint),
        backend, flags
    );
    return scan_block;
end

function C_iio_create_scan_context(backend::String, flags::UInt32=UInt32(0))
    @assert_scan_context scan_context = ccall(
        (:iio_create_scan_context, libIIO),
        Ptr{iio_scan_context}, (Cstring, Cuint),
        backend, flags
    );
    return scan_context;
end

function C_iio_scan_block_destroy(scan_block::Ptr{iio_scan_block})
    ccall(
        (:iio_scan_block_destroy, libIIO),
        Cvoid, (Ptr{iio_scan_block},),
        scan_block
    );
end

function C_iio_scan_block_get_info(scan_block::Ptr{iio_scan_block}, index::UInt32)
    @assert_context_info context_info = ccall(
        (:iio_scan_block_get_info, libIIO),
        Ptr{iio_context_info}, (Ptr{iio_scan_block}, Cuint),
        scan_block, index
    );
    return context_info;
end

function C_iio_scan_block_scan(scan_block::Ptr{iio_scan_block})
    nb_contexts = ccall(
        (:iio_scan_block_scan, libIIO),
        Cssize_t, (Ptr{iio_scan_block},),
        scan_block
    );
    return Base.convert(Int, nb_contexts);
end

function C_iio_scan_context_destroy(scan_context::Ptr{iio_scan_context})
    ccall(
        (:iio_scan_context_destroy, libIIO),
        Cvoid, (Ptr{iio_scan_context},),
        scan_context
    );
end

function C_iio_scan_context_get_info_list(scan_context::Ptr{iio_scan_context}, context_info::Ref{Ptr{Ptr{iio_context_info}}})
    nb_contexts = ccall(
        (:iio_scan_context_get_info_list, libIIO),
        Cssize_t, (Ptr{iio_scan_context}, Ptr{Ptr{Ptr{iio_context_info}}}),
        scan_context, context_info
    );
    return Base.convert(Int, nb_contexts);
end
