#define INTERSCRIPT_COMMAND_LOADCARDS loadcards
#define INTERSCRIPT_COMMAND_LOADSUITE loadsuite
#define INTERSCRIPT_COMMAND_LOADEDSUITE loadedsuite

#define _ ""
#define STR(...) #__VA_ARGS__
#define DEFER_STR(...) STR(__VA_ARGS__)

#define COMMAND_START start
#define COMMAND_SUITES suites
#define COMMAND_LOAD load

list _notecards;
integer commandChannel;

// Logging

log(string msg) { llOwnerSay("[V's Tester] [Loader] " + msg); }
#ifdef INFO
    logInfo(string msg) { log("[INFO] " + msg); }
#else
    #define logInfo(msg)
#endif
#ifdef VERBOSE
    logVerbose(string msg) { log("[VERBOSE] " + msg); }
#else
    #define logVerbose(msg)
#endif

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num != 5000)
            return;

        commandChannel = (integer)((string)id);

        if(str == DEFER_STR(INTERSCRIPT_COMMAND_LOADCARDS))
        {
            _notecards = [];

            llLinksetDataDeleteFound("^NC_.*$", _);

            integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
            if(count > 1)
                log("Found " + (string)count + " notecards, parsing them now..");
            else if(count == 0)
                log("No notecards found, add a notecard with test data to begin.");
            else
                log("Found 1 notecard, parsing it now..");

            string name;
            string queryId;
            while(count--)
            {
                name = llGetInventoryName(INVENTORY_NOTECARD, count);
                queryId = (string)llGetNotecardLine(name, 0);
                _notecards += [name + ":" + queryId + ":0"];
                logVerbose("Parsing notecard: \"" + name + "\".");
            }
        }
        else
        {
            list parts = llParseString2List(str, [" "], []);
            string cmd = (string)parts[0];
            if(cmd == DEFER_STR(INTERSCRIPT_COMMAND_LOADSUITE))
            {
                string name = llDumpList2String(llList2List(parts, 1, -1), " ");
                if(llJsonValueType(llLinksetDataRead("NC_" + name), []) != JSON_OBJECT)
                    log("There is no suite called \"" + name + "\". View available suites using \"/" + (string)commandChannel + " " + DEFER_STR(COMMAND_SUITES) + "\"");
                else
                {
                    log("Loading test suite \"" + llJsonGetValue(llLinksetDataRead("NC_" + name), ["name"]) + "\"");
                    list tests = [];
                    integer i;
                    integer len;
                    list jsonList = llJson2List(llJsonGetValue(llLinksetDataRead("NC_" + name), ["commonActions"]));
                    list jsonItem;
                    len = llGetListLength(jsonList);
                    for(i = 0; i < len; i++)
                    {
                        jsonItem = llJson2List((string)jsonList[i]);
                        llLinksetDataWrite("C_" + (string)jsonItem[0], (string)jsonItem[1]);
                    }
                    jsonList = llJson2List(llJsonGetValue(llLinksetDataRead("NC_" + name), ["tests"]));
                    len = llGetListLength(jsonList);
                    for(i = 0; i < len; i++)
                    {
                        jsonItem = llJson2List((string)jsonList[i]);
                        llLinksetDataWrite("T_" + (string)jsonItem[0], (string)jsonItem[1]);
                        tests += [(string)jsonItem[0]];
                    }
                    if(llGetInventoryType(name + "_PH") == INVENTORY_SCRIPT)
                    {
                        llSetScriptState(name + "_PH", TRUE);
                        llResetOtherScript(name + "_PH");
                    }
                    llMessageLinked(LINK_THIS, 4000, DEFER_STR(INTERSCRIPT_COMMAND_LOADEDSUITE) + " " + name + " " + llDumpList2String(tests, "|"), _);
                    log("Loading finished. Use the command \"/" + (string)id + " " + DEFER_STR(COMMAND_START) + "\" to start the test suite");
                }
            }
        }
    }

    dataserver(key queryid, string data)
    {
        integer i;
        integer len = llGetListLength(_notecards);
        for(i = 0; i < len; i++)
        {
            list parts = llParseString2List((string)_notecards[i], [":"], []);
            if((key)parts[1] == queryid)
            {
                integer lineIndex = (integer)parts[2];
                string name = (string)parts[0];
                string notecardTestData = llLinksetDataRead("NC_" + name);
                while (data != EOF && data != NAK) {
                    if(data != "")
                    {
                        data = llStringTrim(data, STRING_TRIM);
                        notecardTestData += data;
                    }
                    data = llGetNotecardLineSync((string)parts[0], ++lineIndex);
                }

                if (data == NAK)
                {
                    llLinksetDataWrite("NC_" + name, notecardTestData);
                    string _queryId = (string)llGetNotecardLine((string)parts[0], (integer)parts[2]);
                    _notecards = llListReplaceList(_notecards, [name + ":" + _queryId + ":" + (string)lineIndex], i, i);
                }

                if (data == EOF)
                {
                    if(llJsonValueType(notecardTestData, []) == JSON_INVALID)
                        log("Notecard \"" + name + "\" does not contain valid JSON.");
                    else
                    {
                        llLinksetDataWrite("NC_" + name, notecardTestData);
                        log("Notecard \"" + name + "\" loaded. Activate it's suite using \"/" + (string)commandChannel + " " + DEFER_STR(COMMAND_LOAD) + " " + name + "\"");
                    }
                    
                    _notecards = llDeleteSubList(_notecards, i, i);
                }

                return;
            }
        }
    }
}
