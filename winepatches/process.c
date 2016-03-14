/***********************************************************************
 *           GetSystemFirmwareTable       (KERNEL32.@)
 */
struct RawSMBIOSData
{
    BYTE Used20CallingMethod;
    BYTE SMBIOSMajorVersion;
    BYTE SMBIOSMinorVersion;
    BYTE DmiRevision;
    DWORD Length;
    BYTE SMBIOSTableData[];
};

UINT WINAPI GetSystemFirmwareTable(DWORD provider, DWORD id, PVOID buffer, DWORD size)
{
    if (size < 16)
    {
        return 16;
    }

    struct RawSMBIOSData * s = (struct RawSMBIOSData *) buffer;

    s->Used20CallingMethod = 0x00;
    s->SMBIOSMajorVersion = 0x00;
    s->SMBIOSMinorVersion = 0x00;
    s->DmiRevision = 0x00;
    s->Length = 8;
    s->SMBIOSTableData[0] = 0x00;
    s->SMBIOSTableData[1] = 0x01;
    s->SMBIOSTableData[2] = 0x02;
    s->SMBIOSTableData[3] = 0x03;
    s->SMBIOSTableData[4] = 0x04;
    s->SMBIOSTableData[5] = 0x05;
    s->SMBIOSTableData[6] = 0x06;
    s->SMBIOSTableData[7] = 0x07;

    return 16;
}

