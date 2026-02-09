default
{
    state_entry()
    {
        llLinksetDataWrite("IB", (string)(-1 - (integer)("0x" + llGetSubString((string)llGetOwner(), -7, -1)) + 5515));
    }
}