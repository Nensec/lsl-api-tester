integer TEST_CHANNEL;
integer attachmentPoint;
key owner;

log(string msg) { llOwnerSay("[V's Tester] [Relay " + llGetObjectName() + "] " + msg); }

default
{
    on_rez(integer channel)
    {
        TEST_CHANNEL = channel;
        llListen(TEST_CHANNEL, "", NULL_KEY, "");
        owner = llGetOwner();
    }

    attach(key id)
    {
        if(id != NULL_KEY)
            llRegionSayTo(owner, TEST_CHANNEL, "ok");
    }

    state_entry()
    {
        llSetTimerEvent(30);
    }

    listen(integer channel, string name, key id, string message)
    {
        if(channel == TEST_CHANNEL)
        {
            list parts = llParseString2List(message, [" "], []);
            if((string)parts[0] == "die")
            {
                if(llGetAttached())
                    llDetachFromAvatar();
                else
                    llDie();
            }
            else if((string)parts[0] == "init")
                llSetObjectName((string)parts[1]);
            else if((string)parts[0] == "attach")
            {
                attachmentPoint = (integer)parts[1];
                llRequestPermissions(owner, PERMISSION_ATTACH);
            }
            else if((string)parts[0] == "relay")
            {
                string relayMessage = llDumpList2String(llList2List(parts, 3, -1), " ");
                if((integer)parts[1] == 0)
                    llRegionSayTo(owner, (integer)parts[2], relayMessage);
                else if((integer)parts[1] == 1)
                    llSay((integer)parts[2], relayMessage);
                else if((integer)parts[1] == 2)
                    llWhisper((integer)parts[2], relayMessage);
                else if((integer)parts[1] == 3)
                    llShout((integer)parts[2], relayMessage);                
            }
        }
        else
            llRegionSayTo(owner, TEST_CHANNEL, message);
    }

    timer()
    {
        if(llGetAttached())
           llDetachFromAvatar();
        else
           llDie();
    }

    run_time_permissions(integer perm)
    {
        llAttachToAvatarTemp(attachmentPoint);
    }
}