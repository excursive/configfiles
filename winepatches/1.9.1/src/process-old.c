/***********************************************************************
 *           GetSystemFirmwareTable       (KERNEL32.@)
 */
UINT WINAPI GetSystemFirmwareTable(DWORD provider, DWORD id, PVOID buffer, DWORD size)
{
    printf("GetSystemFirmwareTable(%d %d %p %d)\n", provider, id, buffer, size);
    if (size < 2328)
    {
        printf("size not large enough, returning 2328\n");
        return 2328;
    }

    struct RawSMBIOSData
    {
        BYTE Used20CallingMethod;
        BYTE SMBIOSMajorVersion;
        BYTE SMBIOSMinorVersion;
        BYTE DmiRevision;
        DWORD Length;
        BYTE SMBIOSTableData[];
    };

    struct RawSMBIOSData * s = (struct RawSMBIOSData *) buffer;

    s->Used20CallingMethod = 0x00; //?
    s->SMBIOSMajorVersion = 0x02;
    s->SMBIOSMinorVersion = 0x07;
    s->DmiRevision = 0x00; //?
    s->Length = 2320;
    const char tabledata[4640] = "";
    const char * src = tabledata;
    BYTE * i = s->SMBIOSTableData;
    BYTE * end = i + 2320;
    unsigned int value;
    while (i < end && sscanf(src, "%2x", &value) == 1)
    {
        *i = value;
        i++;
        src += 2;
    }
    printf("%2x\n", s->SMBIOSTableData[1]);

    printf("ok\n");
    return 2328;
}
