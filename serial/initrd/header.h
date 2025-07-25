struct SerialBootHeader {
    uint32_t entry_point;       // [0x00] entry IP (e.g. 0x100000)
    uint32_t load_address;      // [0x04] where to load main payload
    uint32_t payload_size;      // [0x08] size of main binary
    uint32_t cmdline_ptr;       // [0x0C] pointer to null-terminated string
    uint32_t initrd_address;    // [0x10] where to load initrd
    uint32_t initrd_size;       // [0x14] size of initrd
};
